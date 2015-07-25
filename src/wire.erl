% simulator of link discovery service in ivanOS
%
%


-module(wire).
-export([new/0, links/1
		]).


new() -> spawn(?MODULE,links,[dict:new()]).


links(Connections) ->
	receive

	%% Messages from Port

		{pkt,Port,Pkt} -> 
			% check if port is wired.
			case dict:fetch(Port,Connections) of
				{not_connected,_,_} -> ok; % drop the packet
					%io:format("Packet dropped from port ~p - port not connected~n",[Port]);
				{Port2,_,_} ->
					{Port,ConnPort_pid,_} = dict:fetch(Port2,Connections),
					ConnPort_pid ! Pkt
			end,
			links(Connections);


		{new_port,Port,Port_pid,Box} -> 
			links(dict:store(Port,{not_connected,Port_pid,Box},Connections));


	%% Requests from Emulator

		{add_wire,Port1,Port2} ->
			Res1 = dict:fetch(Port1,Connections),
			Res2 = dict:fetch(Port2,Connections),

			case {Res1,Res2} of
				{{not_connected,P1_pid,B1},{not_connected,P2_pid,B2}} ->
					links(dict:store(Port2,{Port1,P2_pid,B2},dict:store(Port1,{Port2,P1_pid,B1},Connections)));
				_ ->
					io:format("Error: one or both ports is/are already connected~n"),
					links(Connections)
			end;

		{del_wire,Port1,Port2} ->
			{Port2,P1_pid,B1} = dict:fetch(Port1,Connections),
			{Port1,P2_pid,B2} = dict:fetch(Port2,Connections),
			links(dict:store(Port2,{not_connected,P2_pid,B2},
				dict:store(Port1,{not_connected,P1_pid,B1},Connections)));

		{get_info,Pid} ->
			Pid ! {connections,dict:to_list(Connections)},
			links(Connections);

		{free_ports,Pid} ->
			Pid ! {connections,lists:sort([ {Box,Port} || {Port,{not_connected,_,Box}} <- dict:to_list(Connections) ]) },
			links(Connections);

		_ ->
			links(Connections)
	end.	


