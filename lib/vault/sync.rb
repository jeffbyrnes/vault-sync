# frozen_string_literal: true

require_relative 'sync/command'
require_relative 'sync/version'
require 'tty/logger'
require 'vault'

module Vault
  # One-way copy of HashiCorp Vault KV secrets from an origin to a destionation
  class Sync
    class Error < StandardError; end

    attr_accessor :destination_addr, :destination_token, :namespace, :origin_addr, :origin_token, :origin_path, :destination_path

    def initialize(params)
      @destination_addr  = params[:destination_addr]
      @destination_token = params[:destination_token]
      @namespace         = params['namespace']
      @origin_addr       = params[:origin_addr]
      @origin_token      = params[:origin_token]
      @origin_path       = params[:origin_path]
      @destination_path  = params[:destination_path]
    end

    def origin_vault
      @origin_vault ||= Vault::Client.new(
        address: origin_addr,
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
            # if the key has a slash on the end, we continue recursing
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
      origin_secrets = {}

      vault_paths(@origin_path).each do |origin_path|
        vault_secret_keys(origin_path).each do |key|
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
      origin_secrets.each do |origin_path, _secret|
        $stdout.puts "Writing #{origin_path} to #{destination_path}…"
        # destination_vault.logical.write(destination_path, secret)
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
