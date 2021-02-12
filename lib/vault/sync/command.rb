# frozen_string_literal: true

require 'tty/option'
require 'tty/prompt'
require_relative 'version'

module Vault
  class Sync
    # CLI arguments, flags, and options for vault-sync
    class Command
      include TTY::Option

      usage do
        no_command

        desc 'One-way recursive sync of HashiCorp Vault KV data'
      end

      argument :path do
        required
        desc 'The Vault key path to recursively copy'
      end

      flag :help do
        short '-h'
        long '--help'
        desc 'Print usage'
      end

      flag :version do
        short '-v'
        long '--version'
        desc 'Print version'
      end

      option :origin_addr do
        required
        short '-o'
        long '--origin-address URL'
        desc 'URL for the origin Vault cluster.'
      end

      option :destination_addr do
        required
        short '-d'
        long '--destination-address URL'
        desc 'URL for the destination Vault cluster.'
      end

      option :origin_token do
        short '-t'
        long '--origin-token TOKEN'
        desc 'OPTIONAL: Token for the origin Vault cluster. Defaults to $VAULT_TOKEN_ORIGIN'
      end

      option :destination_token do
        short '-k'
        long '--destination-token TOKEN'
        desc 'OPTIONAL: Token for the destination Vault cluster. Defaults to $VAULT_TOKEN_DESTINATION'
      end

      option :namespace do
        short '-n'
        long '--namespace VAULT_NAMESPACE'
        desc 'OPTIONAL: Namespace to use in both Vault clusters. Defaults to $VAULT_NAMESPACE.'
      end

      def run
        if params[:help]
          print help
          exit
        end

        if params[:version]
          puts Vault::Sync::VERSION
          exit
        end
      end
    end
  end
end
