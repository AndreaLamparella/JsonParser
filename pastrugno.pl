% JSON ::= Object | Array
% Object ::= '{}' | '{' Members '}'
% Members ::= Pair | Pair ',' Members
% Pair ::= String ':' Value
% Array ::= '[]' | '[' Elements ']'
% Elements ::= Value | Value ',' Elements
% Value ::= JSON | Number | String
% Number ::= Digit+ | Digit+ '.' Digit+
% Digit ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
% String ::= '"' AnyCharSansDQ* '"' | '’' AnyCharSansSQ* '’'
% AnyCharSansDQ ::= <qualunque carattere (ASCII) diverso da '"'>
% AnyCharSansSQ ::= <qualunque carattere (ASCII) diverso da '’'>


%% 'asd' -> atomo
%% "asd" -> String

%%%% SISTEMARE I CONCAT


json(O) :- object(O).

json(A) :- array(A).


%%% object/1
% Il predicato è vero quando Input è un oggetto

object(Input) :- 
    togligraffe(Input, I_senza_graffe),
    member_breaker(I_senza_graffe, Lista),
    % atomic_list_concat(Lista, ', ', I_senza_graffe),
    members(Lista).



%%% members/1
% il predicato è vero quando Input è un membro
members([]).
members([H | Tail]) :- 
    pair(H),
    members(Tail).

%%% pair/1
% Il predicato è vero quando Input è una coppia del tipo 'String : Valore' 

pair(Input) :- 
    spezza_pair(Input, S, V),
    stringa(S),                                                              %% ERRORE
    value(V).

%%% array/1
array('').
array(Input) :- 
    togliquadre(Input, E),
    member_breaker(E, Lista),
    % atomic_list_concat(Lista, ', ', E),
    elements(Lista).

%%% elements/1
elements([]).
elements([H | Tail]) :- 
    value(H),
    elements(Tail).


%%% value/1 
value(I) :- num(I).
value(I) :- stringa(I).
value(I) :- json(I).

stringa(S) :-                       %% risistemare '"313"' me lo prende come stringa
    toglivirgolette(S, X),
    atom_string(X, Y),
    string(Y).

num(An) :-                           %% se mi arriva un numero atomico (es. '42')
    atom_number(An, N), 
    number(N).               

num(Input) :-                       %% se mi arriva una stringa con un numero (es "42")
    toglivirgolette(Input, X),
    num(X).

% %%% string/1
% stringa(Input) :-
%     toglivirgolette(Input, C),
%     atom_codes(C, Lista_ascii),
%     carattere(Lista_ascii).

% %%% carattere/1
% carattere([]).
% carattere([H | Tail]) :-
%     not(H is 34),
%     carattere(Tail).

%%% togligraffe/2
togligraffe(I, I_senza_graffe) :- 
    atom_concat('{', I_sx, I),
    atom_concat(I_senza_graffe, '}', I_sx).
    
%%% togliquadre/2
togliquadre(I, I_senza_quadre) :- 
    atom_concat('[', I_sx, I),
    atom_concat(I_senza_quadre, ']', I_sx).

%%% toglivirgolette/2
toglivirgolette(I, I_pulito) :- 
    atom_concat('"', I_sx, I),
    atom_concat(I_pulito, '"', I_sx).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

json_parse(JSONString, Object) :-
    rimuovi_newline(JSONString, String),
    parse_supp([String], [], Object).

parse_supp([], _, _) :- !.

parse_supp([H | Tail], Precedente, Obj) :- 
  %%  atom_string(Head, H),                                   %% lo converto a stringa
    object(H), !,                                             %% SE è UN OGGETTO
    togligraffe(H, H_senza_graffe),                         %% tolgo le graffe
    member_breaker(H_senza_graffe, Lista_membri),
    % atomic_list_concat(Lista_membri, ', ', H_senza_graffe), %% lo spezzo nella lista [P, P, P]
    parse_supp_pair(Lista_membri, Precedente, Obj),              %% chiamo sul primo membro
    parse_supp(Tail, Precedente, Obj).                      %% chiamo sulla coda

parse_supp([H | Tail], Precedente, Obj) :-  
   %% atom_string(Head, H),                                       %% lo converto a stringa
    array(H), !,                                                 %% SE è UN ARRAY
    togliquadre(H, H_senza_graffe),                             %% tolgo le quadre
    member_breaker(H_senza_graffe, Lista_elementi),
    % atomic_list_concat(Lista_elementi, ', ', H_senza_graffe),   %% spezzo nella lista [E, E, E]
    parse_supp(Lista_elementi, Precedente, Obj),                %% chiamo sulla testa
    parse_supp(Tail, Precedente, Obj).                          %% chiamo sulla coda

%%%%%%%%%%%%%%%%%% WIP

parse_supp_pair([H | Tail], Precedente, Obj) :- 
%%  atom_string(Head, H),                           %% lo converto a stringa
    pair(H), !,                                       %% SE è un PAIR       %% PROBABILMENTE INUTILE
    spezza_pair(H, S, V),                           %% lo spezzo nella lista [S, V]  
    stringa(S),                                      %% se S è una stringa  %% PROBABILMENTE è INUTILE
    check_value(V, V_trattata),                      %% chiamo su V
    incapsula_tonde(S, V_trattata, Coppia),
    append(Precedente, [Coppia], Successiva),
    parse_supp_pair(Tail, Successiva, Obj).              %% chiamo sulla coda

parse_supp_pair([], X, X).

% parse_supp([H | Tail], Precedente, Obj) :-
%     num(H),     %%%WIP

% parse_supp([Head | Tail], Precedente, Obj) :-
%     atom_string(Head, H),                           %% converto a stringa               %%% DUBBIO
%     string(H),                                      %% se è un STRING
%     append(Precedente, H, Obj).



%%% Supporto a caso



check_value(N, N) :- num(N), !.

check_value(S, S) :- stringa(S), !.

check_value(V, X) :- 
    json(V),                                    %% probabilmente inutile
    parse_supp([V], [], X).



trim(String, Trim) :-
    atom_chars(String, Chars),
    trim_sx(Chars, Tsx),
    reverse(Tsx, Tsxm),
    trim_sx(Tsxm, Tdxm),
    reverse(Tdxm, Tdx),
    atom_chars(Trim, Tdx).

trim_sx([' ' | Tail], T) :-
    trim_sx(Tail, T).

trim_sx([H | Tail], T) :-
    not(H = ' '),
    append([H], Tail, T).


%%FUNGE


spezza_pair(Coppia, St, Vt) :- 
    atom_chars(Coppia, Chars),
    spezza_pair_sup(Chars, V_chars),
    append(S_chars_dp, V_chars, Chars),
    atom_chars(V, V_chars),
    atom_chars(S_dp, S_chars_dp),
    atom_concat(S, ':', S_dp),
    trim(S, St),
    trim(V, Vt).

spezza_pair_sup([':' | Tail], Tail) :-!.

spezza_pair_sup([H | Tail], Restante):-
    not(H = ':'),
    spezza_pair_sup(Tail, Restante).

%%FUNGE

rimuovi_newline(String, Riga) :-
    atomic_list_concat(Lista, '\n', String),
    concatena_lista(Lista, "", Riga).

%%FUNGE

concatena_lista([], X, X).

concatena_lista([H | Tail], Precedente, String) :-
    atom_concat(Precedente, H, Successiva),
    concatena_lista(Tail, Successiva, String).

%%FUNGE
incapsula_tonde(S, V, Capsula) :-
    atom_concat('(', S, C1),
    atom_concat(C1, ', ', C2),
    atom_concat(C2, V, C3),
    atom_concat(C3, ')', Capsula).

%%% Funziona, ma mi da troppe opzioni e va ottimizzato

member_breaker(String, Lista) :-
    atom_chars(String, Chars),
    spezza_members(Chars, "", [], Lista).

%%


spezza_members([], Buffer, Precedente, Finale) :-
    append(Precedente, [Buffer], Finale), !.

spezza_members([',' | Tail], Buffer, Precedente, Finale) :-      %% caso della virgola
    append(Precedente, [Buffer], Successiva),                    %% aggiorno ciè che mi porto dietro   
    spezza_members(Tail, "", Successiva, Finale).                %% itero sulla coda resettando il buffer

spezza_members(['{' | Tail], Buffer, Precedente, Finale) :-      %% caso della graffa aperta
    atom_concat(Buffer, '{', Buffer_con_graffa),               %% aggiorno il buffer con la graffa
    spezza_alla_graffa(Tail, Sottoggetto, Coda),    %% recupero il sottoggetto che inizia
    atom_concat(Buffer_con_graffa, Sottoggetto, Buffer_con_so),
    spezza_members(Coda, Buffer_con_so, Precedente, Finale).       %% aggiorno il buffer con il sottoggetto ed itero sulla coda

spezza_members(['[' | Tail], Buffer, Precedente, Finale) :-      %% caso della quadra aperta
    atom_concat(Buffer, '[', Buffer_con_quadra),               %% aggiorno il buffer con la quadra
    spezza_alla_quadra(Tail, Sottoggetto, Coda),    %% recupero il sottoggetto che inizia
    atom_concat(Buffer_con_quadra, Sottoggetto, Buffer_con_array),
    spezza_members(Coda, Buffer_con_array, Precedente, Finale).       %% aggiorno il buffer con il sottoggetto ed itero sulla coda

spezza_members([H | Tail], Buffer, Precedente, Finale) :-         %% caso generale
    atom_concat(Buffer, H, Buffer_aggiornato),                 %% aggiorno il buffer
    spezza_members(Tail, Buffer_aggiornato, Precedente, Finale). %% itero sulla coda


%%
% il predicato è vero quando Sottoggetto è il sottooggetto estratto dalla lista di chars Chars e Chars_Coda sono i chars riamnenti
%% N.B. Chars ha la prima graffa rimossa
spezza_alla_graffa(Chars, Sottoggetto, Chars_coda) :-
    spezza_sottoggetto(Chars, 1, Chars_coda),
    append(Chars_SO, Chars_coda, Chars),
    atom_chars(Sottoggetto, Chars_SO).

spezza_sottoggetto(Tail, 0, Tail):- !.

spezza_sottoggetto(['{' | Tail], Contatore, Lista_Tail) :-
    Count is Contatore + 1,
    spezza_sottoggetto(Tail, Count, Lista_Tail).
    
spezza_sottoggetto(['}' | Tail], Contatore, Lista_Tail) :-
    Count is Contatore - 1,
    spezza_sottoggetto(Tail, Count, Lista_Tail).

spezza_sottoggetto([H | Tail], Contatore,  Lista_Tail) :-
    not(H = '{'),
    not(H = '}'),
    spezza_sottoggetto(Tail, Contatore, Lista_Tail).

%%
% il predicato è vero quando Sottoggetto è il sottoarray estratto dalla lista di chars Chars e Chars_Coda sono i chars riamnenti
%% N.B. Chars ha la prima quadra rimossa
spezza_alla_quadra(Chars, Sottoggetto, Chars_coda) :-
    spezza_sottoarray(Chars, 1, Chars_coda),
    append(Chars_SO, Chars_coda, Chars),
    atom_chars(Sottoggetto, Chars_SO).

spezza_sottoarray(Tail, 0, Tail):- !.

spezza_sottoarray(['[' | Tail], Contatore, Lista_Tail) :-
    Count is Contatore + 1,
    spezza_sottoarray(Tail, Count, Lista_Tail).
    
spezza_sottoarray([']' | Tail], Contatore, Lista_Tail) :-
    Count is Contatore - 1,
    spezza_sottoarray(Tail, Count, Lista_Tail).

spezza_sottoarray([H | Tail], Contatore,  Lista_Tail) :-
    not(H = '['),
    not(H = ']'),
    spezza_sottoarray(Tail, Contatore, Lista_Tail).



%%%%%COSE UTILI
% {"type": "menu", "value": "File", "items": [{"value": "New", "action": "CreateNewDoc"}, {"value": "Open", "action": "OpenDoc"}, {"value": "Close", "action": "CloseDoc"}]}

% atomic_list_concat([gnu, gnat], ', ', A).     =====> A = 'gnu, gnat'
% atom_concat(1, 2, X)                          =====> X = '12'
% atom_codes(pippo, X)                          =====> X = [112, 105, 112, 112, 111]
% split_string("a.b.c.d", ".", "", L)           =====> L = ["a", "b", "c", "d"].

%% a, {b, {c, d}, e}, f

%%['"', a, '"', ':', 5, ',', '"', p, '"', ':', '{', '"', q, '"', ':', '"', z, '"', ',', '"', e, '"', ':', 1, '}']
%% '"a" : 5, "p" : { "q" : "z", "e" : 1 }'