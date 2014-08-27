-module(stout).

-include_lib("lager/include/lager.hrl").

% API
-export([test/0]).

% Callbacks
-export([format/2]).
-export([format/3]).

-define(
    is_io(Item),
    is_binary(Item) orelse is_list(Item) orelse is_integer(Item)
).

%--- API ----------------------------------------------------------------------

test() ->
    lager:debug([{binary, <<"hello">>}], "Debug", []),
    lager:info([{number, 2.3}], "Info", []),
    lager:notice([{pid, self()}], "Notice", []),
    lager:warning("Warning"),
    lager:error("Error"),
    lager:critical("Critical"),
    lager:alert("Alert"),
    lager:emergency("Emergency").

%--- Callbacks ----------------------------------------------------------------

format(Msg, Config) -> format(Msg, Config, []).

format(Msg, Config, _WAT) ->
    % io:format("format/3 ~p ~p ~p~n", [Msg, Config, _WAT]),
    print(Msg, Config).

%--- Internal -----------------------------------------------------------------

print(_Msg, []) ->
    [];
print(Msg, [{Key, Options}|Config]) ->
    case get(Key, Msg) of
        undefined -> print(Msg, Config);
        Data      -> [format_opts(Data, Options)|print(Msg, Config)]
    end;
print(Msg, [Key|Config]) when is_atom(Key) ->
    case get(Key, Msg) of
        undefined -> print(Msg, Config);
        Data      -> [Data|print(Msg, Config)]
    end;
print(Msg, [Item|Config]) when ?is_io(Item) ->
    [Item|print(Msg, Config)].

get(date, Msg) ->
    element(1, lager_msg:datetime(Msg));
get(time, Msg) ->
    element(2, lager_msg:datetime(Msg));
get(severity, Msg) ->
    {tag, lager_msg:severity_as_int(Msg), atom_to_list(lager_msg:severity(Msg))};
get(message, Msg) ->
    lager_msg:message(Msg);
get(pid, Msg) ->
    Pid = proplists:get_value(pid, lager_msg:metadata(Msg)),
    case Pid of
        Pid when is_pid(Pid)  -> pid_to_list(Pid);
        Pid when is_list(Pid) -> Pid;
        emulator              -> "<emulator>";
        undefined             -> undefined
    end;
get(Key, Msg) ->
    Meta = lager_msg:metadata(Msg),
    proplists:get_value(Key, Meta).

format_opts({tag, _Tag, Item}, []) ->
    Item;
format_opts(Item, []) ->
    Item;
format_opts(Item, [Option|Options]) ->
    format_opts(format_item(Option, Item), Options);
format_opts(Item, Option) ->
    format_item(Option, Item).

format_item(color, Item)              -> colorize(Item);
format_item(Option, {tag, Tag, Item}) -> {tag, Tag, format_item(Option, Item)};
format_item(upper, Item)              -> upper(to_list(Item));
format_item(lower, Item)              -> lower(to_list(Item));
format_item({format, Format}, Item)   -> io_lib:format(Format, [Item]);
format_item(Color, Item)              -> color:Color(Item).

colorize({tag, ?DEBUG, Str})     -> {tag, ?DEBUG, color:blueb(Str)};
colorize({tag, ?INFO, Str})      -> {tag, ?INFO, color:whiteb(Str)};
colorize({tag, ?NOTICE, Str})    -> {tag, ?NOTICE, color:greenb(Str)};
colorize({tag, ?WARNING, Str})   -> {tag, ?WARNING, color:yellowb(Str)};
colorize({tag, ?ERROR, Str})     -> {tag, ?ERROR, color:redb(Str)};
colorize({tag, ?CRITICAL, Str})  -> {tag, ?CRITICAL, color:black(color:on_yellow(Str))};
colorize({tag, ?ALERT, Str})     -> {tag, ?ALERT, color:black(color:on_magenta(Str))};
colorize({tag, ?EMERGENCY, Str}) -> {tag, ?EMERGENCY, color:black(color:on_red(Str))}.

to_list(Item) -> binary_to_list(iolist_to_binary(Item)).

upper([]) ->
    [];
upper([$;, C, $m|Str]) -> % Bold
    [$;, C, $m|upper(Str)];
upper([$\e, $[, C, $m|Str]) -> % Single code
    [$\e, $[, C, $m|upper(Str)];
upper([$\e, $[, C1, C2, $m|Str]) -> % Double code
    [$\e, $[, C1, C2, $m|upper(Str)];
upper([C|Str]) when is_integer(C), $a =< C, C =< $z ->
    [C - 32|upper(Str)];
upper([C|Str]) when is_integer(C), 16#E0 =< C, C =< 16#F6 ->
    [C - 32|upper(Str)];
upper([C|Str]) when is_integer(C), 16#F8 =< C, C =< 16#FE ->
    [C - 32|upper(Str)];
upper([C|Str]) ->
    [C|upper(Str)].

lower([]) ->
    [];
lower([$;, C, $m|Str]) -> % Bold
    [$;, C, $m|lower(Str)];
lower([$\e, $[, C, $m|Str]) -> % Single code
    [$\e, $[, C, $m|lower(Str)];
lower([$\e, $[, C1, C2, $m|Str]) -> % Double code
    [$\e, $[, C1, C2, $m|lower(Str)];
lower([C|Str]) when is_integer(C), $a =< C, C =< $z ->
    [C + 32|lower(Str)];
lower([C|Str]) when is_integer(C), 16#E0 =< C, C =< 16#F6 ->
    [C + 32|lower(Str)];
lower([C|Str]) when is_integer(C), 16#F8 =< C, C =< 16#FE ->
    [C + 32|lower(Str)];
lower([C|Str]) ->
    [C|lower(Str)].
