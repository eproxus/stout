[![Travis][travis badge]][travis] [![Hex.pm Version][hex version badge]][hex] [![Hex.pm License][hex license badge]][hex] [![Erlang Versions][erlang version badge]][travis]

# Stout

<strong>St</strong>ylized <strong>out</strong>put for [Lager](https://github.com/basho/lager).

Stout is a better version of the `lager_default_formatter` formatter. It
follows the same pattern, a list of either IO data or tags. In Stout, each tag
can be accompanied by a set of format options.

## Features

* Color support (explicit for all tags and automatic for severity)
* Formatting tags will only print something if the tag exist in the Lager
  metadata. For example, wrapping a tag in `[` and `]` using `{format, "[~s]"}`
  would only show the brackets if the tag exists.
* Automatic formatting of all metadata tags.

## Example

The following code:

```erlang
lager:debug([{binary, <<"hello">>}], "Debug", []),
lager:info([{number, 2.3}], "Info", []),
lager:notice([{pid, self()}], "Notice", []),
lager:warning("Warning"),
lager:error("Error"),
lager:critical("Critical"),
lager:alert("Alert"),
lager:emergency("Emergency").
```

With the following configuration:

```erlang
[
    {date, blackb}, " ",
    {time, yellow}, " ",
    {severity, [upper, {format, "~.7s"}, color, {format, "~s "}]},
    {'$metadata', [], [node, application, line]}, " ",
    message, "\n"
]
```

Which would yield:

![Example](https://raw.githubusercontent.com/eproxus/stout/master/screenshot.png)

## Items

### `IOData :: iolist() | binary() | list() | char()`

Any IO data (`iolist()`, `binary()`, `list()`, or `char()`) is printed as is in
each log message.

### `Tag :: atom()`

A tag (`atom()`) is picked from the message metadata. Predefined tags in Stout
messages are:
* `date` The date from Lager's datetime record.
* `time` The time from Lager's datetime record.
* `severity` The severity of the message.
* `message` The actual log message.

### `TagOpt :: {Tag, option()} | {Tag, [option()]}`

A tag with options is formatted according to the options given (see Options
below).

### `{'$metadata', Formats :: [TagOpt], Skipped :: [Tag]}`

The metadata item formats all tags in the message in a key value style
(`key=value`). Special overrides can be given in the `Formats` list which is a
list of tags with options (`[TagOpt]`). Any tag in `Skipped` will not be
printed.

## Options

Options are applied one after the other in the sequence they appear in. The
order can be significant depending on which options are used. For example,
adding padding first and then a color would color the padding (`[{format, "~s
"}, blue]`). Coloring first and padding afterwards, would only color the text
and not the padding (`[blue, {format, "~s "}]`) because the padding is applied
*around* the alread blue text.

### `upper`

Transform to upper case.

### `lower`

Transform to lower case.

### `color`

Colorize severity levels (**only** supported for the `severity` tag).

### `{format, Fmt}`

Format string according to [`io:format/3`](http://www.erlang.org/doc/man/io.html#format-3).

### `Color :: color()`

A color supported by the [color](https://github.com/julianduque/erlang-color) library.

## Handler Configuration

To enable this in Lager for both console and file, try the following handler
configuration for Lager:

```erlang
{handlers, [
    {lager_console_backend, [
        debug,
        {stout, [
            {date, blackb}, " ",
            {time, yellow}, " ",
            {severity, [upper, {format, "~.7s"}, color, {format, "~s "}]},
            {'$metadata', [], [node, application, line]}, " ",
            message, "\n"
        ]}
    ]},
    {lager_file_backend, [
        {level, debug},
        {file, "log/debug.log"},
        {formatter, stout},
        {formatter_config, [
            {date, blackb}, " ",
            {time, yellow}, " ",
            {severity, [upper, {format, "~.7s"}, color, {format, "~s "}]},
            {'$metadata', [], [node, application, line]}, " ",
            message, "\n"
        ]}
    ]}
]}
```



[travis]: https://travis-ci.org/eproxus/stout
[travis badge]: https://img.shields.io/travis/eproxus/stout.svg?style=flat-square
[hex]: https://hex.pm/packages/stout
[hex version badge]: https://img.shields.io/hexpm/v/stout.svg?style=flat-square
[hex license badge]: https://img.shields.io/hexpm/l/stout.svg?style=flat-square
[erlang version badge]: https://img.shields.io/badge/erlang-17.5%20to%2019.2-blue.svg?style=flat-square
