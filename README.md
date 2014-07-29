Parliament
==========

A Ruby app that listens to GitHub events and merges pull requests when specified criteria have been met. Inspired by [plus-pull](https://github.com/christofdamian/plus-pull).

## Usage

When Pull requests have satisfied the following criteria, they are automatically merged:
* The sum of `+1` and `-1` in comments is greater than or equal to the configured sum. *Note: only the first vote in each comment is counted.*
* There are no comments containing `/\[blocker\]/i` (`[blocker]` or `[Blocker]` or `[BLOCKER]`, etc).
* The pull request can be merged.
* Optionally (defaults to true), the commit status must be `success`.

*Note: When parsing comments, text inside `~~` (Markdown for ~~strikethrough~~) is ignored.*

## Installation/Setup

### Parliament
TBD

### GitHub
Setup is easy, just setup the webhook for all events to a repo and it'll start handling merge requests (Parliament handles `+form` and `+json`, so use what you'd prefer).

Make sure you add `/webhook` to the end of the URL, as follows:

```
https://www.yourserver.com/webhook
```

## Configuration (coming soon)
Parliament can be configured by setting configuration options within the configuration block in `application.rb`, i.e.

```ruby
Parliament.configure do |config|

  config.github_token = <GitHub Oath Token>

  # the sum of +1/-1
  #
  # default: 3
  config.sum = 2

  # current status must be success
  #
  # default: true
  config.status = false
  
  # an array of required voters' github usernames
  # also accepts an array returning block that is called on each check.
  #
  # default: empty array
  config.required do
      [...]
  end

end
```

## Alternatives
* [plus-pull](https://github.com/christofdamian/plus-pull)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Running the Tests

`bundle exec rake`

## License

Parliament is released under the MIT License. See the bundled LICENSE file for
details.
