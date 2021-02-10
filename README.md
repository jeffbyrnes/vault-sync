# Vault::Sync

A CLI tool for one-way sync of a key/value secrets engine from one HashiCorp Vault cluster to another.

## Usage

We’ve packaged this up into a Docker container for ease of use, and all you need to do is pass in the necessary env vars & parameters.

Bear in mind that this _will_ overwrite any identical paths, so it is meant for a one-way sync, e.g., from prod → dev.

```bash
docker run --rm athenahealth/vault-sync "vault-sync $key_path $VAULT_ADDR_ORIGIN $VAULT_TOKEN_ORIGIN $VAULT_ADDR_DESTINATION $VAULT_TOKEN_DESTINATION"
```

If you’d prefer to run it directly, you’ll need a working Ruby v3.x environment. From there, you install the gem:

```bash
gem install vault-sync
```

Then you can use it like so:

```bash
vault-sync $key_path \
    $VAULT_ADDR_ORIGIN      $VAULT_TOKEN_ORIGIN \
    $VAULT_ADDR_DESTINATION $VAULT_TOKEN_DESTINATION
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jeffbyrnes/vault-sync. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/jeffbyrnes/vault-sync/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Vault::Sync project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jeffbyrnes/vault-sync/blob/master/CODE_OF_CONDUCT.md).
