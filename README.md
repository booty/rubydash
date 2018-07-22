# rubydash - Your Ruby Dashboard

People, particularly developers, have many information sources to monitor these days.

Social media, multiple email accounts, monitoring services, etc.

It'd be awfully nice to watch them from a single terminal window.

That's rubydash's job!

![rubydash demo](screenshots/rubydash-with-formatting.png?raw=true "rubydash")

## What's It Do?

In a nutshell, rubydash:

1. Pulls data from remote (or local!) sources
2. Caches that data in a local sqlite data store for a configurable time
3. Displays that info in a terminal window

Code for each of the data sources lives in `drivers/`. Right now, Reddit, Twitter, and Gmail are supported. The plan is to support many more of these data sources. Adding a new data source is as simple as adding a new file & driver class to `drivers/` and perhaps updating the Gemfile.

My current `~/.rubydash/config.yml`:

![rubydash config.yml](screenshots/config-yml.png?raw=true "rubydash config.yml")

## This Is Very "Beta"

I've only tested this on my Macbook Pro, running iTerm2 3.1.7 and Ruby 2.5.1

It's guaranteed NOT to work in Terminal.app because Terminal.app won't understand the control codes to display hyperlinks.

## Neat Features That Currently Work

There's a lot to do, but right now it's usable for me in a basic way.

1. Caching of data in a sqlite database works. Helps you avoid those pesky API rate limits.
2. Rubydash will detect your terminal width and format data correctly
3. Hyperlinks! [Did you know that iTerm2, GNOME Terminal, and others support hyperlinks?](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda) In iTerm2, you can hold down `command` and click on a feed name or item title.
4. You can specify multiple accounts for the same service in your `config.yml` - you could monitor three Twitter accounts and twelve Reddit accounts if that's your thing.
5. Pass the `--faker` argument to rubydash if you'd like to sanitize your output so you can share with others: `bundle exec ruby rubydash.rb --faker`
6. Database schema versioning
7. Does not cause the user to develop a skin rash as far as I know


## High-Priority TODOs

1. More drivers for more data sources. Next on my list: ~~RSS~~, Github, Darksky
1. Disable hyperlinks for terminal applications that don't support them (at least support a command line arg for this if we can't auto detect)
1. Configurable display modes ("full", "compact", "widget", etc) on a per-data-source basis. One example use case would be a "weather widget" or a system CPU usage monitor that would take up only a single line, and not have its own heading (ie, "widget mode"?) **[in progress]**
1. Figure out how to run this in a loop. My initial intent was to run it in a loop with `watch -n3 --color bundle exec ruby rubydash.rb` but it seems `watch` chokes on the color codes.
1. A more sane project structure (should probably be a gem?)
1. Better "new user" experience... walk users through setting up `config.yml`, inform them of required fields that are missing, etc.
1. Fetch data in parallel w/ multiple threads? Not sure if this would work w/ Sqlite. Also not sure if this is needed. While fetches are slow, they are also meant to be quite occasional...