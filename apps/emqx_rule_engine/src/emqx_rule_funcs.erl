%%--------------------------------------------------------------------
%% Copyright (c) 2020-2024 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_rule_funcs).

-include("rule_engine.hrl").
-include_lib("emqx/include/logger.hrl").

-elvis([{elvis_style, god_modules, disable}]).

%% IoT Funcs
-export([
    msgid/0,
    qos/0,
    flags/0,
    flag/1,
    topic/0,
    topic/1,
    clientid/0,
    clientip/0,
    peerhost/0,
    username/0,
    payload/0,
    payload/1,
    contains_topic/2,
    contains_topic/3,
    contains_topic_match/2,
    contains_topic_match/3,
    null/0
]).

%% Arithmetic Funcs
-export([
    '+'/2,
    '-'/2,
    '*'/2,
    '/'/2,
    'div'/2,
    mod/2,
    eq/2
]).

%% Math Funcs
-export([
    abs/1,
    acos/1,
    acosh/1,
    asin/1,
    asinh/1,
    atan/1,
    atanh/1,
    ceil/1,
    cos/1,
    cosh/1,
    exp/1,
    floor/1,
    fmod/2,
    log/1,
    log10/1,
    log2/1,
    power/2,
    round/1,
    sin/1,
    sinh/1,
    sqrt/1,
    tan/1,
    tanh/1
]).

%% Bitwise operations
-export([
    bitnot/1,
    bitand/2,
    bitor/2,
    bitxor/2,
    bitsl/2,
    bitsr/2
]).

%% binary and bitstring Funcs
-export([
    bitsize/1,
    bytesize/1,
    subbits/2,
    subbits/3,
    subbits/4,
    subbits/5,
    subbits/6
]).

%% Data Type Conversion
-export([
    str/1,
    str_utf8/1,
    bool/1,
    int/1,
    float/1,
    float/2,
    float2str/2,
    map/1,
    bin2hexstr/1,
    hexstr2bin/1
]).

%% Data Type Validation Funcs
-export([
    is_null/1,
    is_null_var/1,
    is_not_null/1,
    is_not_null_var/1,
    is_str/1,
    is_bool/1,
    is_int/1,
    is_float/1,
    is_num/1,
    is_map/1,
    is_array/1
]).

%% String Funcs
-export([
    lower/1,
    ltrim/1,
    reverse/1,
    rtrim/1,
    strlen/1,
    substr/2,
    substr/3,
    trim/1,
    upper/1,
    split/2,
    split/3,
    concat/2,
    tokens/2,
    tokens/3,
    sprintf_s/2,
    pad/2,
    pad/3,
    pad/4,
    replace/3,
    replace/4,
    regex_match/2,
    regex_replace/3,
    ascii/1,
    find/2,
    find/3,
    join_to_string/1,
    join_to_string/2,
    join_to_sql_values_string/1,
    jq/2,
    jq/3,
    unescape/1
]).

%% Map Funcs
-export([map_new/0]).

-export([
    map_get/2,
    map_get/3,
    map_put/3,
    map_keys/1,
    map_values/1,
    map_to_entries/1
]).

%% For backward compatibility
-export([
    mget/2,
    mget/3,
    mput/3
]).

%% Array Funcs
-export([
    nth/2,
    length/1,
    sublist/2,
    sublist/3,
    first/1,
    last/1,
    contains/2
]).

%% Hash Funcs
-export([
    md5/1,
    sha/1,
    sha256/1
]).

%% zip Funcs
-export([
    zip/1,
    unzip/1
]).

%% gzip Funcs
-export([
    gzip/1,
    gunzip/1
]).

%% compressed Funcs
-export([
    zip_compress/1,
    zip_uncompress/1
]).

%% Data encode and decode
-export([
    base64_encode/1,
    base64_decode/1,
    json_decode/1,
    json_encode/1,
    term_decode/1,
    term_encode/1
]).

%% Date functions
-export([
    now_rfc3339/0,
    now_rfc3339/1,
    unix_ts_to_rfc3339/1,
    unix_ts_to_rfc3339/2,
    rfc3339_to_unix_ts/1,
    rfc3339_to_unix_ts/2,
    now_timestamp/0,
    now_timestamp/1,
    format_date/3,
    format_date/4,
    date_to_unix_ts/3,
    date_to_unix_ts/4,
    timezone_to_second/1,
    timezone_to_offset_seconds/1
]).

%% See extra_functions_module/0 and set_extra_functions_module/1 in the
%% emqx_rule_engine module
-callback handle_rule_function(atom(), list()) -> any() | {error, no_match_for_function}.

%% MongoDB specific date functions. These functions return a date tuple. The
%% MongoDB bridge converts such date tuples to a MongoDB date type. The
%% following functions are therefore only useful for rules with at least one
%% MongoDB action.
-export([
    mongo_date/0,
    mongo_date/1,
    mongo_date/2
]).

%% Random Funcs
-export([
    random/0,
    uuid_v4/0,
    uuid_v4_no_hyphen/0
]).

%% Proc Dict Func
-export([
    proc_dict_get/1,
    proc_dict_put/2,
    proc_dict_del/1,
    kv_store_get/1,
    kv_store_get/2,
    kv_store_put/2,
    kv_store_del/1
]).

-export(['$handle_undefined_function'/2]).

-compile(
    {no_auto_import, [
        abs/1,
        ceil/1,
        floor/1,
        round/1,
        map_get/2
    ]}
).

-import(emqx_utils_calendar, [time_unit/1, now_to_rfc3339/0, now_to_rfc3339/1, epoch_to_rfc3339/2]).

%% @doc "msgid()" Func
msgid() ->
    fun
        (#{id := MsgId}) -> MsgId;
        (_) -> undefined
    end.

%% @doc "qos()" Func
qos() ->
    fun
        (#{qos := QoS}) -> QoS;
        (_) -> undefined
    end.

%% @doc "topic()" Func
topic() ->
    fun
        (#{topic := Topic}) -> Topic;
        (_) -> undefined
    end.

%% @doc "topic(N)" Func
topic(I) when is_integer(I) ->
    fun
        (#{topic := Topic}) ->
            lists:nth(I, emqx_topic:tokens(Topic));
        (_) ->
            undefined
    end.

%% @doc "flags()" Func
flags() ->
    fun
        (#{flags := Flags}) -> Flags;
        (_) -> #{}
    end.

%% @doc "flags(Name)" Func
flag(Name) ->
    fun
        (#{flags := Flags}) -> emqx_rule_maps:nested_get({var, Name}, Flags);
        (_) -> undefined
    end.

%% @doc "clientid()" Func
clientid() ->
    fun
        (#{from := ClientId}) -> ClientId;
        (_) -> undefined
    end.

%% @doc "username()" Func
username() ->
    fun
        (#{username := Username}) -> Username;
        (_) -> undefined
    end.

%% @doc "clientip()" Func
clientip() ->
    peerhost().

peerhost() ->
    fun
        (#{peerhost := Addr}) -> Addr;
        (_) -> undefined
    end.

payload() ->
    fun
        (#{payload := Payload}) -> Payload;
        (_) -> undefined
    end.

payload(Path) ->
    fun
        (#{payload := Payload}) when erlang:is_map(Payload) ->
            emqx_rule_maps:nested_get(map_path(Path), Payload);
        (_) ->
            undefined
    end.

%% @doc Check if a topic_filter contains a specific topic
%% TopicFilters = [{<<"t/a">>, #{qos => 0}].
-spec contains_topic(emqx_types:topic_filters(), emqx_types:topic()) ->
    true | false.
contains_topic(TopicFilters, Topic) ->
    case find_topic_filter(Topic, TopicFilters, fun eq/2) of
        not_found -> false;
        _ -> true
    end.
contains_topic(TopicFilters, Topic, QoS) ->
    case find_topic_filter(Topic, TopicFilters, fun eq/2) of
        {_, #{qos := QoS}} -> true;
        _ -> false
    end.

-spec contains_topic_match(emqx_types:topic_filters(), emqx_types:topic()) ->
    true | false.
contains_topic_match(TopicFilters, Topic) ->
    case find_topic_filter(Topic, TopicFilters, fun emqx_topic:match/2) of
        not_found -> false;
        _ -> true
    end.
contains_topic_match(TopicFilters, Topic, QoS) ->
    case find_topic_filter(Topic, TopicFilters, fun emqx_topic:match/2) of
        {_, #{qos := QoS}} -> true;
        _ -> false
    end.

find_topic_filter(Filter, TopicFilters, Func) ->
    try
        [
            case Func(Topic, Filter) of
                true -> throw(Result);
                false -> ok
            end
         || Result = #{topic := Topic} <- TopicFilters
        ],
        not_found
    catch
        throw:Result -> Result
    end.

null() ->
    undefined.

bytesize(IoList) ->
    erlang:iolist_size(IoList).

%%------------------------------------------------------------------------------
%% Arithmetic Funcs
%%------------------------------------------------------------------------------

%% plus 2 numbers
'+'(X, Y) when is_number(X), is_number(Y) ->
    X + Y;
%% string concatenation
%% this requires one of the arguments is string, the other argument will be converted
%% to string automatically (implicit conversion)
'+'(X, Y) when is_binary(X); is_binary(Y) ->
    concat(X, Y).

'-'(X, Y) when is_number(X), is_number(Y) ->
    X - Y.

'*'(X, Y) when is_number(X), is_number(Y) ->
    X * Y.

'/'(X, Y) when is_number(X), is_number(Y) ->
    X / Y.

'div'(X, Y) when is_integer(X), is_integer(Y) ->
    X div Y.

mod(X, Y) when is_integer(X), is_integer(Y) ->
    X rem Y.

eq(X, Y) ->
    X == Y.

%%------------------------------------------------------------------------------
%% Math Funcs
%%------------------------------------------------------------------------------

abs(N) when is_integer(N) ->
    erlang:abs(N).

acos(N) when is_number(N) ->
    math:acos(N).

acosh(N) when is_number(N) ->
    math:acosh(N).

asin(N) when is_number(N) ->
    math:asin(N).

asinh(N) when is_number(N) ->
    math:asinh(N).

atan(N) when is_number(N) ->
    math:atan(N).

atanh(N) when is_number(N) ->
    math:atanh(N).

ceil(N) when is_number(N) ->
    erlang:ceil(N).

cos(N) when is_number(N) ->
    math:cos(N).

cosh(N) when is_number(N) ->
    math:cosh(N).

exp(N) when is_number(N) ->
    math:exp(N).

floor(N) when is_number(N) ->
    erlang:floor(N).

fmod(X, Y) when is_number(X), is_number(Y) ->
    math:fmod(X, Y).

log(N) when is_number(N) ->
    math:log(N).

log10(N) when is_number(N) ->
    math:log10(N).

log2(N) when is_number(N) ->
    math:log2(N).

power(X, Y) when is_number(X), is_number(Y) ->
    math:pow(X, Y).

round(N) when is_number(N) ->
    erlang:round(N).

sin(N) when is_number(N) ->
    math:sin(N).

sinh(N) when is_number(N) ->
    math:sinh(N).

sqrt(N) when is_number(N) ->
    math:sqrt(N).

tan(N) when is_number(N) ->
    math:tan(N).

tanh(N) when is_number(N) ->
    math:tanh(N).

%%------------------------------------------------------------------------------
%% Bits Funcs
%%------------------------------------------------------------------------------

bitnot(I) when is_integer(I) ->
    bnot I.

bitand(X, Y) when is_integer(X), is_integer(Y) ->
    X band Y.

bitor(X, Y) when is_integer(X), is_integer(Y) ->
    X bor Y.

bitxor(X, Y) when is_integer(X), is_integer(Y) ->
    X bxor Y.

bitsl(X, I) when is_integer(X), is_integer(I) ->
    X bsl I.

bitsr(X, I) when is_integer(X), is_integer(I) ->
    X bsr I.

bitsize(Bits) when is_bitstring(Bits) ->
    bit_size(Bits).

subbits(Bits, Len) when is_integer(Len), is_bitstring(Bits) ->
    subbits(Bits, 1, Len).

subbits(Bits, Start, Len) when is_integer(Start), is_integer(Len), is_bitstring(Bits) ->
    get_subbits(Bits, Start, Len, <<"integer">>, <<"unsigned">>, <<"big">>).

subbits(Bits, Start, Len, Type) when
    is_integer(Start), is_integer(Len), is_bitstring(Bits)
->
    get_subbits(Bits, Start, Len, Type, <<"unsigned">>, <<"big">>).

subbits(Bits, Start, Len, Type, Signedness) when
    is_integer(Start), is_integer(Len), is_bitstring(Bits)
->
    get_subbits(Bits, Start, Len, Type, Signedness, <<"big">>).

subbits(Bits, Start, Len, Type, Signedness, Endianness) when
    is_integer(Start), is_integer(Len), is_bitstring(Bits)
->
    get_subbits(Bits, Start, Len, Type, Signedness, Endianness).

get_subbits(Bits, Start, Len, Type, Signedness, Endianness) ->
    Begin = Start - 1,
    case Bits of
        <<_:Begin, Rem/bits>> when Rem =/= <<>> ->
            Sz = bit_size(Rem),
            do_get_subbits(Rem, Sz, Len, Type, Signedness, Endianness);
        _ ->
            undefined
    end.

-define(match_bits(Bits0, Pattern, ElesePattern),
    case Bits0 of
        Pattern ->
            SubBits;
        ElesePattern ->
            SubBits
    end
).
do_get_subbits(Bits, Sz, Len, <<"integer">>, <<"unsigned">>, <<"big">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/integer-unsigned-big-unit:1, _/bits>>,
        <<SubBits:Sz/integer-unsigned-big-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"float">>, <<"unsigned">>, <<"big">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/float-unsigned-big-unit:1, _/bits>>,
        <<SubBits:Sz/float-unsigned-big-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"bits">>, <<"unsigned">>, <<"big">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/bits-unsigned-big-unit:1, _/bits>>,
        <<SubBits:Sz/bits-unsigned-big-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"integer">>, <<"signed">>, <<"big">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/integer-signed-big-unit:1, _/bits>>,
        <<SubBits:Sz/integer-signed-big-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"float">>, <<"signed">>, <<"big">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/float-signed-big-unit:1, _/bits>>,
        <<SubBits:Sz/float-signed-big-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"bits">>, <<"signed">>, <<"big">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/bits-signed-big-unit:1, _/bits>>,
        <<SubBits:Sz/bits-signed-big-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"integer">>, <<"unsigned">>, <<"little">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/integer-unsigned-little-unit:1, _/bits>>,
        <<SubBits:Sz/integer-unsigned-little-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"float">>, <<"unsigned">>, <<"little">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/float-unsigned-little-unit:1, _/bits>>,
        <<SubBits:Sz/float-unsigned-little-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"bits">>, <<"unsigned">>, <<"little">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/bits-unsigned-little-unit:1, _/bits>>,
        <<SubBits:Sz/bits-unsigned-little-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"integer">>, <<"signed">>, <<"little">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/integer-signed-little-unit:1, _/bits>>,
        <<SubBits:Sz/integer-signed-little-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"float">>, <<"signed">>, <<"little">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/float-signed-little-unit:1, _/bits>>,
        <<SubBits:Sz/float-signed-little-unit:1>>
    );
do_get_subbits(Bits, Sz, Len, <<"bits">>, <<"signed">>, <<"little">>) ->
    ?match_bits(
        Bits,
        <<SubBits:Len/bits-signed-little-unit:1, _/bits>>,
        <<SubBits:Sz/bits-signed-little-unit:1>>
    ).

%%------------------------------------------------------------------------------
%% Data Type Conversion Funcs
%%------------------------------------------------------------------------------

str(Data) ->
    emqx_utils_conv:bin(Data).

str_utf8(Data) when is_binary(Data); is_list(Data) ->
    unicode:characters_to_binary(Data);
str_utf8(Data) ->
    unicode:characters_to_binary(str(Data)).

bool(Data) ->
    emqx_utils_conv:bool(Data).

int(Data) ->
    emqx_utils_conv:int(Data).

float(Data) ->
    emqx_utils_conv:float(Data).

float(Data, Decimals) when Decimals > 0 ->
    Data1 = emqx_utils_conv:float(Data),
    list_to_float(float_to_list(Data1, [{decimals, Decimals}])).

float2str(Float, Precision) ->
    float_to_binary(Float, [{decimals, Precision}, compact]).

map(Bin) when is_binary(Bin) ->
    case emqx_utils_json:decode(Bin) of
        Map = #{} ->
            Map;
        _ ->
            error(badarg, [Bin])
    end;
map(List) when is_list(List) ->
    maps:from_list(List);
map(Map = #{}) ->
    Map;
map(Data) ->
    error(badarg, [Data]).

bin2hexstr(Bin) when is_binary(Bin) ->
    emqx_utils:bin_to_hexstr(Bin, upper);
%% If Bin is a bitstring which is not divisible by 8, we pad it and then do the
%% conversion
bin2hexstr(Bin) when is_bitstring(Bin), (8 - (bit_size(Bin) rem 8)) >= 4 ->
    PadSize = 8 - (bit_size(Bin) rem 8),
    Padding = <<0:PadSize>>,
    BinToConvert = <<Padding/bitstring, Bin/bitstring>>,
    <<_FirstByte:8, HexStr/binary>> = emqx_utils:bin_to_hexstr(BinToConvert, upper),
    HexStr;
bin2hexstr(Bin) when is_bitstring(Bin) ->
    PadSize = 8 - (bit_size(Bin) rem 8),
    Padding = <<0:PadSize>>,
    BinToConvert = <<Padding/bitstring, Bin/bitstring>>,
    emqx_utils:bin_to_hexstr(BinToConvert, upper).

hexstr2bin(Str) when is_binary(Str) ->
    emqx_utils:hexstr_to_bin(Str).

%%------------------------------------------------------------------------------
%% NULL Funcs
%%------------------------------------------------------------------------------

is_null(undefined) -> true;
is_null(_Data) -> false.

%% Similar to is_null/1, but also works for the JSON value 'null'
is_null_var(null) -> true;
is_null_var(Data) -> is_null(Data).

is_not_null(Data) ->
    not is_null(Data).

is_not_null_var(Data) ->
    not is_null_var(Data).

is_str(T) when is_binary(T) -> true;
is_str(_) -> false.

is_bool(T) when is_boolean(T) -> true;
is_bool(_) -> false.

is_int(T) when is_integer(T) -> true;
is_int(_) -> false.

is_float(T) when erlang:is_float(T) -> true;
is_float(_) -> false.

is_num(T) when is_number(T) -> true;
is_num(_) -> false.

is_map(T) when erlang:is_map(T) -> true;
is_map(_) -> false.

is_array(T) when is_list(T) -> true;
is_array(_) -> false.

%%------------------------------------------------------------------------------
%% String Funcs
%%------------------------------------------------------------------------------

lower(S) when is_binary(S) ->
    string:lowercase(S).

ltrim(S) when is_binary(S) ->
    string:trim(S, leading).

reverse(S) when is_binary(S) ->
    iolist_to_binary(string:reverse(S)).

rtrim(S) when is_binary(S) ->
    string:trim(S, trailing).

strlen(S) when is_binary(S) ->
    string:length(S).

substr(S, Start) when is_binary(S), is_integer(Start) ->
    string:slice(S, Start).

substr(S, Start, Length) when
    is_binary(S),
    is_integer(Start),
    is_integer(Length)
->
    string:slice(S, Start, Length).

trim(S) when is_binary(S) ->
    string:trim(S).

upper(S) when is_binary(S) ->
    string:uppercase(S).

split(S, P) when is_binary(S), is_binary(P) ->
    [R || R <- string:split(S, P, all), R =/= <<>> andalso R =/= ""].

split(S, P, <<"notrim">>) ->
    string:split(S, P, all);
split(S, P, <<"leading_notrim">>) ->
    string:split(S, P, leading);
split(S, P, <<"leading">>) when is_binary(S), is_binary(P) ->
    [R || R <- string:split(S, P, leading), R =/= <<>> andalso R =/= ""];
split(S, P, <<"trailing_notrim">>) ->
    string:split(S, P, trailing);
split(S, P, <<"trailing">>) when is_binary(S), is_binary(P) ->
    [R || R <- string:split(S, P, trailing), R =/= <<>> andalso R =/= ""].

tokens(S, Separators) ->
    [list_to_binary(R) || R <- string:lexemes(binary_to_list(S), binary_to_list(Separators))].

tokens(S, Separators, <<"nocrlf">>) ->
    [
        list_to_binary(R)
     || R <- string:lexemes(binary_to_list(S), binary_to_list(Separators) ++ [$\r, $\n, [$\r, $\n]])
    ].

%% implicit convert args to strings, and then do concatenation
concat(S1, S2) ->
    unicode:characters_to_binary([str(S1), str(S2)], unicode).

sprintf_s(Format, Args) when is_list(Args) ->
    erlang:iolist_to_binary(io_lib:format(binary_to_list(Format), Args)).

pad(S, Len) when is_binary(S), is_integer(Len) ->
    iolist_to_binary(string:pad(S, Len, trailing)).

pad(S, Len, <<"trailing">>) when is_binary(S), is_integer(Len) ->
    iolist_to_binary(string:pad(S, Len, trailing));
pad(S, Len, <<"both">>) when is_binary(S), is_integer(Len) ->
    iolist_to_binary(string:pad(S, Len, both));
pad(S, Len, <<"leading">>) when is_binary(S), is_integer(Len) ->
    iolist_to_binary(string:pad(S, Len, leading)).

pad(S, Len, <<"trailing">>, Char) when is_binary(S), is_integer(Len), is_binary(Char) ->
    Chars = unicode:characters_to_list(Char, utf8),
    iolist_to_binary(string:pad(S, Len, trailing, Chars));
pad(S, Len, <<"both">>, Char) when is_binary(S), is_integer(Len), is_binary(Char) ->
    Chars = unicode:characters_to_list(Char, utf8),
    iolist_to_binary(string:pad(S, Len, both, Chars));
pad(S, Len, <<"leading">>, Char) when is_binary(S), is_integer(Len), is_binary(Char) ->
    Chars = unicode:characters_to_list(Char, utf8),
    iolist_to_binary(string:pad(S, Len, leading, Chars)).

replace(SrcStr, P, RepStr) when is_binary(SrcStr), is_binary(P), is_binary(RepStr) ->
    iolist_to_binary(string:replace(SrcStr, P, RepStr, all)).

replace(SrcStr, P, RepStr, <<"all">>) when is_binary(SrcStr), is_binary(P), is_binary(RepStr) ->
    iolist_to_binary(string:replace(SrcStr, P, RepStr, all));
replace(SrcStr, P, RepStr, <<"trailing">>) when
    is_binary(SrcStr), is_binary(P), is_binary(RepStr)
->
    iolist_to_binary(string:replace(SrcStr, P, RepStr, trailing));
replace(SrcStr, P, RepStr, <<"leading">>) when is_binary(SrcStr), is_binary(P), is_binary(RepStr) ->
    iolist_to_binary(string:replace(SrcStr, P, RepStr, leading)).

regex_match(Str, RE) ->
    case re:run(Str, RE, [global, {capture, none}]) of
        match -> true;
        nomatch -> false
    end.

regex_replace(SrcStr, RE, RepStr) ->
    re:replace(SrcStr, RE, RepStr, [global, {return, binary}]).

ascii(Char) when is_binary(Char) ->
    [FirstC | _] = binary_to_list(Char),
    FirstC.

find(S, P) when is_binary(S), is_binary(P) ->
    find_s(S, P, leading).

find(S, P, <<"trailing">>) when is_binary(S), is_binary(P) ->
    find_s(S, P, trailing);
find(S, P, <<"leading">>) when is_binary(S), is_binary(P) ->
    find_s(S, P, leading).

find_s(S, P, Dir) ->
    case string:find(S, P, Dir) of
        nomatch -> <<"">>;
        SubStr -> SubStr
    end.

join_to_string(List) when is_list(List) ->
    join_to_string(<<", ">>, List).
join_to_string(Sep, List) when is_list(List), is_binary(Sep) ->
    iolist_to_binary(lists:join(Sep, [str(Item) || Item <- List])).
join_to_sql_values_string(List) ->
    QuotedList =
        [
            case is_list(Item) of
                true ->
                    emqx_placeholder:quote_sql(emqx_utils_json:encode(Item));
                false ->
                    emqx_placeholder:quote_sql(Item)
            end
         || Item <- List
        ],
    iolist_to_binary(lists:join(<<", ">>, QuotedList)).

-spec jq(FilterProgram, JSON, TimeoutMS) -> Result when
    FilterProgram :: binary(),
    JSON :: binary() | term(),
    TimeoutMS :: non_neg_integer(),
    Result :: [term()].
jq(FilterProgram, JSONBin, TimeoutMS) when
    is_binary(FilterProgram), is_binary(JSONBin)
->
    case jq:process_json(FilterProgram, JSONBin, TimeoutMS) of
        {ok, Result} ->
            [json_decode(JSONString) || JSONString <- Result];
        {error, ErrorReason} ->
            erlang:throw({jq_exception, ErrorReason})
    end;
jq(FilterProgram, JSONTerm, TimeoutMS) when is_binary(FilterProgram) ->
    JSONBin = json_encode(JSONTerm),
    jq(FilterProgram, JSONBin, TimeoutMS).

-spec jq(FilterProgram, JSON) -> Result when
    FilterProgram :: binary(),
    JSON :: binary() | term(),
    Result :: [term()].
jq(FilterProgram, JSONBin) ->
    ConfigRootKey = emqx_rule_engine_schema:namespace(),
    jq(
        FilterProgram,
        JSONBin,
        emqx_config:get([
            ConfigRootKey,
            jq_function_default_timeout
        ])
    ).

unescape(Bin) when is_binary(Bin) ->
    UnicodeList = unicode:characters_to_list(Bin, utf8),
    UnescapedUnicodeList = unescape_string(UnicodeList),
    UnescapedUTF8Bin = unicode:characters_to_binary(UnescapedUnicodeList, utf32, utf8),
    case UnescapedUTF8Bin of
        Out when is_binary(Out) ->
            Out;
        Error ->
            throw({invalid_unicode_character, Error})
    end.

unescape_string(Input) -> unescape_string(Input, []).

unescape_string([], Acc) ->
    lists:reverse(Acc);
unescape_string([$\\, $\\ | Rest], Acc) ->
    unescape_string(Rest, [$\\ | Acc]);
unescape_string([$\\, $n | Rest], Acc) ->
    unescape_string(Rest, [$\n | Acc]);
unescape_string([$\\, $t | Rest], Acc) ->
    unescape_string(Rest, [$\t | Acc]);
unescape_string([$\\, $r | Rest], Acc) ->
    unescape_string(Rest, [$\r | Acc]);
unescape_string([$\\, $b | Rest], Acc) ->
    unescape_string(Rest, [$\b | Acc]);
unescape_string([$\\, $f | Rest], Acc) ->
    unescape_string(Rest, [$\f | Acc]);
unescape_string([$\\, $v | Rest], Acc) ->
    unescape_string(Rest, [$\v | Acc]);
unescape_string([$\\, $' | Rest], Acc) ->
    unescape_string(Rest, [$\' | Acc]);
unescape_string([$\\, $" | Rest], Acc) ->
    unescape_string(Rest, [$\" | Acc]);
unescape_string([$\\, $? | Rest], Acc) ->
    unescape_string(Rest, [$\? | Acc]);
unescape_string([$\\, $a | Rest], Acc) ->
    unescape_string(Rest, [$\a | Acc]);
%% Start of HEX escape code
unescape_string([$\\, $x | [$0 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$1 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$2 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$3 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$4 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$5 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$6 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$7 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$8 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$9 | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$A | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$B | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$C | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$D | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$E | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$F | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$a | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$b | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$c | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$d | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$e | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
unescape_string([$\\, $x | [$f | _] = HexStringStart], Acc) ->
    unescape_handle_hex_string(HexStringStart, Acc);
%% We treat all other escape sequences as not valid input to leave room for
%% extending the function to support more escape codes
unescape_string([$\\, X | _Rest], _Acc) ->
    erlang:throw({unrecognized_escape_sequence, list_to_binary([$\\, X])});
unescape_string([First | Rest], Acc) ->
    unescape_string(Rest, [First | Acc]).

unescape_handle_hex_string(HexStringStart, Acc) ->
    {RemainingString, Num} = parse_hex_string(HexStringStart),
    unescape_string(RemainingString, [Num | Acc]).

parse_hex_string(SeqStartingWithHexDigit) ->
    parse_hex_string(SeqStartingWithHexDigit, []).

parse_hex_string([], Acc) ->
    ReversedAcc = lists:reverse(Acc),
    {[], list_to_integer(ReversedAcc, 16)};
parse_hex_string([First | Rest] = String, Acc) ->
    case is_hex_digit(First) of
        true ->
            parse_hex_string(Rest, [First | Acc]);
        false ->
            ReversedAcc = lists:reverse(Acc),
            {String, list_to_integer(ReversedAcc, 16)}
    end.

is_hex_digit($0) -> true;
is_hex_digit($1) -> true;
is_hex_digit($2) -> true;
is_hex_digit($3) -> true;
is_hex_digit($4) -> true;
is_hex_digit($5) -> true;
is_hex_digit($6) -> true;
is_hex_digit($7) -> true;
is_hex_digit($8) -> true;
is_hex_digit($9) -> true;
is_hex_digit($A) -> true;
is_hex_digit($B) -> true;
is_hex_digit($C) -> true;
is_hex_digit($D) -> true;
is_hex_digit($E) -> true;
is_hex_digit($F) -> true;
is_hex_digit($a) -> true;
is_hex_digit($b) -> true;
is_hex_digit($c) -> true;
is_hex_digit($d) -> true;
is_hex_digit($e) -> true;
is_hex_digit($f) -> true;
is_hex_digit(_) -> false.

%%------------------------------------------------------------------------------
%% Array Funcs
%%------------------------------------------------------------------------------

nth(N, L) when is_integer(N), is_list(L) ->
    lists:nth(N, L).

length(List) when is_list(List) ->
    erlang:length(List).

sublist(Len, List) when is_integer(Len), is_list(List) ->
    lists:sublist(List, Len).

sublist(Start, Len, List) when is_integer(Start), is_integer(Len), is_list(List) ->
    lists:sublist(List, Start, Len).

first(List) when is_list(List) ->
    hd(List).

last(List) when is_list(List) ->
    lists:last(List).

contains(Elm, List) when is_list(List) ->
    lists:member(Elm, List).

map_new() ->
    #{}.

map_get(Key, Map) ->
    map_get(Key, Map, undefined).

map_get(Key, Map, Default) ->
    emqx_rule_maps:nested_get(map_path(Key), Map, Default).

map_put(Key, Val, Map) ->
    emqx_rule_maps:nested_put(map_path(Key), Val, Map).

mget(Key, Map) ->
    mget(Key, Map, undefined).

mget(Key, Map0, Default) ->
    Map = map(Map0),
    case maps:find(Key, Map) of
        {ok, Val} ->
            Val;
        error when is_atom(Key) ->
            %% the map may have an equivalent binary-form key
            BinKey = emqx_utils_conv:bin(Key),
            case maps:find(BinKey, Map) of
                {ok, Val} -> Val;
                error -> Default
            end;
        error when is_binary(Key) ->
            %% the map may have an equivalent atom-form key
            try
                AtomKey = list_to_existing_atom(binary_to_list(Key)),
                case maps:find(AtomKey, Map) of
                    {ok, Val} -> Val;
                    error -> Default
                end
            catch
                error:badarg ->
                    Default
            end;
        error ->
            Default
    end.

mput(Key, Val, Map0) ->
    Map = map(Map0),
    case maps:find(Key, Map) of
        {ok, _} ->
            maps:put(Key, Val, Map);
        error when is_atom(Key) ->
            %% the map may have an equivalent binary-form key
            BinKey = emqx_utils_conv:bin(Key),
            case maps:find(BinKey, Map) of
                {ok, _} -> maps:put(BinKey, Val, Map);
                error -> maps:put(Key, Val, Map)
            end;
        error when is_binary(Key) ->
            %% the map may have an equivalent atom-form key
            try
                AtomKey = list_to_existing_atom(binary_to_list(Key)),
                case maps:find(AtomKey, Map) of
                    {ok, _} -> maps:put(AtomKey, Val, Map);
                    error -> maps:put(Key, Val, Map)
                end
            catch
                error:badarg ->
                    maps:put(Key, Val, Map)
            end;
        error ->
            maps:put(Key, Val, Map)
    end.

map_keys(Map) ->
    maps:keys(map(Map)).
map_values(Map) ->
    maps:values(map(Map)).
map_to_entries(Map) ->
    [#{key => K, value => V} || {K, V} <- maps:to_list(map(Map))].

%%------------------------------------------------------------------------------
%% Hash Funcs
%%------------------------------------------------------------------------------

md5(S) when is_binary(S) ->
    hash(md5, S).

sha(S) when is_binary(S) ->
    hash(sha, S).

sha256(S) when is_binary(S) ->
    hash(sha256, S).

hash(Type, Data) ->
    emqx_utils:bin_to_hexstr(crypto:hash(Type, Data), lower).

%%------------------------------------------------------------------------------
%% gzip Funcs
%%------------------------------------------------------------------------------

gzip(S) when is_binary(S) ->
    zlib:gzip(S).

gunzip(S) when is_binary(S) ->
    zlib:gunzip(S).

%%------------------------------------------------------------------------------
%% zip Funcs
%%------------------------------------------------------------------------------

zip(S) when is_binary(S) ->
    zlib:zip(S).

unzip(S) when is_binary(S) ->
    zlib:unzip(S).

%%------------------------------------------------------------------------------
%% zip_compress Funcs
%%------------------------------------------------------------------------------

zip_compress(S) when is_binary(S) ->
    zlib:compress(S).

zip_uncompress(S) when is_binary(S) ->
    zlib:uncompress(S).

%%------------------------------------------------------------------------------
%% Data encode and decode Funcs
%%------------------------------------------------------------------------------

base64_encode(Data) when is_binary(Data) ->
    base64:encode(Data).

base64_decode(Data) when is_binary(Data) ->
    base64:decode(Data).

json_encode(Data) ->
    emqx_utils_json:encode(Data).

json_decode(Data) ->
    emqx_utils_json:decode(Data, [return_maps]).

term_encode(Term) ->
    erlang:term_to_binary(Term).

term_decode(Data) when is_binary(Data) ->
    erlang:binary_to_term(Data).

%%------------------------------------------------------------------------------
%% Random Funcs
%%------------------------------------------------------------------------------
random() ->
    rand:uniform().

uuid_v4() ->
    uuid_str(uuid:get_v4(), binary_standard).

uuid_v4_no_hyphen() ->
    uuid_str(uuid:get_v4(), binary_nodash).

%%------------------------------------------------------------------------------
%% Dict Funcs
%%------------------------------------------------------------------------------

-define(DICT_KEY(KEY), {'@rule_engine', KEY}).
proc_dict_get(Key) ->
    erlang:get(?DICT_KEY(Key)).

proc_dict_put(Key, Val) ->
    erlang:put(?DICT_KEY(Key), Val).

proc_dict_del(Key) ->
    erlang:erase(?DICT_KEY(Key)).

kv_store_put(Key, Val) ->
    ets:insert(?KV_TAB, {Key, Val}).

kv_store_get(Key) ->
    kv_store_get(Key, undefined).
kv_store_get(Key, Default) ->
    case ets:lookup(?KV_TAB, Key) of
        [{_, Val}] -> Val;
        _ -> Default
    end.

kv_store_del(Key) ->
    ets:delete(?KV_TAB, Key).

%%--------------------------------------------------------------------
%% Date functions
%%--------------------------------------------------------------------

now_rfc3339() ->
    now_to_rfc3339().

now_rfc3339(Unit) ->
    now_to_rfc3339(time_unit(Unit)).

unix_ts_to_rfc3339(Epoch) ->
    epoch_to_rfc3339(Epoch, second).

unix_ts_to_rfc3339(Epoch, Unit) when is_integer(Epoch) ->
    epoch_to_rfc3339(Epoch, time_unit(Unit)).

rfc3339_to_unix_ts(DateTime) ->
    rfc3339_to_unix_ts(DateTime, second).

rfc3339_to_unix_ts(DateTime, Unit) when is_binary(DateTime) ->
    calendar:rfc3339_to_system_time(
        binary_to_list(DateTime),
        [{unit, time_unit(Unit)}]
    ).

now_timestamp() ->
    erlang:system_time(second).

now_timestamp(Unit) ->
    erlang:system_time(time_unit(Unit)).

format_date(TimeUnit, Offset, FormatString) ->
    Unit = time_unit(TimeUnit),
    TimeEpoch = erlang:system_time(Unit),
    format_date(Unit, Offset, FormatString, TimeEpoch).

format_date(TimeUnit, Offset, FormatString, TimeEpoch) ->
    Unit = time_unit(TimeUnit),
    emqx_utils_conv:bin(
        lists:concat(
            emqx_utils_calendar:format(TimeEpoch, Unit, Offset, FormatString)
        )
    ).

date_to_unix_ts(TimeUnit, FormatString, InputString) ->
    Unit = time_unit(TimeUnit),
    emqx_utils_calendar:parse(InputString, Unit, FormatString).

date_to_unix_ts(TimeUnit, Offset, FormatString, InputString) ->
    Unit = time_unit(TimeUnit),
    OffsetSecond = emqx_utils_calendar:offset_second(Offset),
    OffsetDelta = erlang:convert_time_unit(OffsetSecond, second, Unit),
    date_to_unix_ts(Unit, FormatString, InputString) - OffsetDelta.

timezone_to_second(TimeZone) ->
    timezone_to_offset_seconds(TimeZone).

timezone_to_offset_seconds(TimeZone) ->
    emqx_utils_calendar:offset_second(TimeZone).

'$handle_undefined_function'(sprintf, [Format | Args]) ->
    erlang:apply(fun sprintf_s/2, [Format, Args]);
%% This is for functions that should be handled in another module
%% (currently this module is emqx_schema_registry_serde in the case of EE but
%% could be changed to another module in the future).
'$handle_undefined_function'(FunctionName, Args) ->
    case emqx_rule_engine:extra_functions_module() of
        undefined ->
            throw_sql_function_not_supported(FunctionName, Args);
        Mod ->
            case Mod:handle_rule_function(FunctionName, Args) of
                {error, no_match_for_function} ->
                    throw_sql_function_not_supported(FunctionName, Args);
                Result ->
                    Result
            end
    end.

-spec throw_sql_function_not_supported(atom(), list()) -> no_return().
throw_sql_function_not_supported(FunctionName, Args) ->
    error({sql_function_not_supported, function_literal(FunctionName, Args)}).

map_path(Key) ->
    {path, [{key, P} || P <- string:split(Key, ".", all)]}.

function_literal(Fun, []) when is_atom(Fun) ->
    iolist_to_binary(atom_to_list(Fun) ++ "()");
function_literal(Fun, [FArg | Args]) when is_atom(Fun), is_list(Args) ->
    WithFirstArg = io_lib:format("~ts(~0p", [atom_to_list(Fun), FArg]),
    FuncLiteral =
        lists:foldl(
            fun(Arg, Literal) ->
                io_lib:format("~ts, ~0p", [Literal, Arg])
            end,
            WithFirstArg,
            Args
        ) ++ ")",
    iolist_to_binary(FuncLiteral);
function_literal(Fun, Args) ->
    {invalid_func, {Fun, Args}}.

mongo_date() ->
    maybe_isodate_format(erlang:timestamp()).

mongo_date(MillisecondsTimestamp) ->
    maybe_isodate_format(convert_timestamp(MillisecondsTimestamp)).

mongo_date(Timestamp, Unit) ->
    InsertedTimeUnit = time_unit(Unit),
    ScaledEpoch = erlang:convert_time_unit(Timestamp, InsertedTimeUnit, millisecond),
    mongo_date(ScaledEpoch).

maybe_isodate_format(ErlTimestamp) ->
    case emqx_rule_sqltester:is_test_runtime_env() of
        false ->
            ErlTimestamp;
        true ->
            %% if this is called from sqltest, we need to convert it to the ISODate() format,
            %% so that it can be correctly converted into a JSON string.
            isodate_format(ErlTimestamp)
    end.

isodate_format({MegaSecs, Secs, MicroSecs}) ->
    SystemTimeMs = (MegaSecs * 1000_000_000_000 + Secs * 1000_000 + MicroSecs) div 1000,
    Ts3339Str = calendar:system_time_to_rfc3339(SystemTimeMs, [{unit, millisecond}, {offset, "Z"}]),
    iolist_to_binary(["ISODate(", Ts3339Str, ")"]).

convert_timestamp(MillisecondsTimestamp) ->
    MicroTimestamp = MillisecondsTimestamp * 1000,
    MegaSecs = MicroTimestamp div 1000_000_000_000,
    Secs = MicroTimestamp div 1000_000 - MegaSecs * 1000_000,
    MicroSecs = MicroTimestamp rem 1000_000,
    {MegaSecs, Secs, MicroSecs}.

uuid_str(UUID, DisplayOpt) ->
    uuid:uuid_to_string(UUID, DisplayOpt).
