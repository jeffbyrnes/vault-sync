# frozen_string_literal: true

require_relative 'sync/version'
require 'vault'

module Vault
  module Sync
    class Error < StandardError; end

    extend self

    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Recursive sync for a path in Vault.\n\nUsage: vault-sync [options]"

      opts.on('-p PATH', '--path PATH', String, 'Path at the origin Vault cluster to read from. E.g. secret/foo/') do |v|
        options[:path] = v
      end

      opts.on('-o VAULT_ADDR', '--origin-address VAULT_ADDR', URI, 'URL for the origin Vault cluster') do |v|
        options[:origin_addr] = v
      end

      opts.on('-t VAULT_TOKEN',
              '--origin-token VAULT_TOKEN',
              String,
              'OPTIONAL: Token for the origin Vault cluster. Can be provided via $VAULT_TOKEN_ORIGIN') do |v|
        options[:origin_token] = v
      end

      opts.on('-d VAULT_ADDR', '--destination-address VAULT_ADDR', URI, 'URL for the destination Vault cluster') do |v|
        options[:destination_addr] = v
      end

      opts.on('-k VAULT_TOKEN',
              '--destination-token VAULT_TOKEN',
              String,
              'OPTIONAL: Token for the destination Vault cluster. Can be provided via $VAULT_TOKEN_DESTINATION') do |v|
        options[:destination_token] = v
      end

      opts.on('-n VAULT_NAMESPACE',
              '--namespace VAULT_NAMESPACE',
              'Namespace to use in both Vault clusters. Can be provided via $VAULT_NAMESPACE.') do |v|
        options[:namespace] = v
      end

      opts.on('-h', '--help', 'Display this help') do
        puts opts
        exit
      end

      opts.on('-v', '--version', 'Display the current script version') do
        puts "vault-sync - v#{VERSION}"
        exit
      end
    end
    parser.parse!

    def origin_token
      @origin_token ||= options[:origin_token].nil? ? ENV['VAULT_TOKEN_ORIGIN'] : options[:origin_token]
    end

    def destination_token
      @destination_token ||= if options[:destination_token].nil?
                               ENV['VAULT_TOKEN_DESTINATION']
                             else
                               options[:destination_token]
                             end
    end

    def namespace
      @namespace ||= begin
        ENV['VAULT_NAMESPACE'] if options[:namespace].nil?
        options[:namespace]
      end
    end

    def origin_vault
      @origin_vault ||= Vault::Client.new(
        address: options[:origin_addr],
        namespace: namespace,
        token: origin_token
      )
    end

    def destination_vault
      @destination_vault ||= Vault::Client.new(
        address: destination_addr,
        namespace: namespace,
        token: destination_token
      )
    end

    # Uncover the full path of every subkey under a given vault key
    def vault_paths(keys = 'secret/')
      # We need to work with an array
      keys = validate(keys)

      # the first element should have a slash on the end, otherwise
      # this function is likely being called improperly
      keys.each do |key|
        raise ArgumentError, "The supplied path #{key} should end in a slash." unless key[-1] == '/'

        # go through each key and add all sub-keys to the array
        origin_vault.with_retries(Vault::HTTPConnectionError) do
          origin_vault.logical.list(key).each do |subkey|
            # if the key has a slash on the end, we must go deeper
            keys.push("#{key}#{subkey}") if subkey[-1] == '/'
          end
        end
      end

      # Remove duplicates (probably unnecessary), and sort
      keys.uniq.sort
    end

    # Find all of the secrets sitting under an array of vault paths
    def vault_secret_keys(vault_paths)
      # We need to work with an array
      vault_paths = validate(vault_paths)

      vault_secrets = []

      vault_paths.each do |key|
        origin_vault.with_retries(Vault::HTTPConnectionError) do
          origin_vault.logical.list(key).each do |secret|
            vault_secrets.push("#{key}#{secret}") unless secret[-1] == '/'
          end
        end
      end

      # return a sorted array
      vault_secrets.sort
    end

    def origin_secrets
      # Check we have the required arguments
      raise OptionParser::MissingArgument, 'PATH is required. Try the --help argument.' if options[:path].nil?

      if options[:origin_addr].nil? || options[:destination_addr].nil?
        raise OptionParser::MissingArgument, 'Origin and destination URLs are required'
      end

      if origin_token.nil? || destination_token.nil?
        raise OptionParser::MissingArgument,
              'Origin and destination tokens are required, please set them via arguments or env vars.'
      end

      origin_secrets = {}

      vault_paths(options[:path]).each do |path|
        vault_secret_keys(path).each do |key|
          origin_secret = origin_vault.logical.read(key)

          if origin_secret.respond_to? :data
            $stdout.puts "Reading #{key}"
            origin_secrets[key] = origin_secret.data
          else
            $stdout.puts "Skipped #{key} (no data)"
          end
        end
      end

      origin_secrets
    end

    def run!
      origin_secrets.each do |path, secret|
        $stdout.puts "Writing #{path}…"
        destination_vault.logical.write(path, secret)
      end
    end

    private

    def validate(keys)
      keys = [keys] if keys.is_a?(String)

      unless keys.is_a?(Array)
        raise ArgumentError,
              'The supplied path must be a string or an array of strings.'
      end

      keys
    end
  end
end
