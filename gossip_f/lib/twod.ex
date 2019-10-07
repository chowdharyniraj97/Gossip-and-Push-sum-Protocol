defmodule Twod do
 use GenServer
 def fire(n,_topology) do
    Registry.start_link(name: :my_registry, keys: :unique)
    Enum.map(1..n,fn(x) -> start_node(x) end)
    list=Registry.select(:my_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    plist=Enum.reduce(list,[],fn(x,acc)->
        acc ++ [elem(x,1)]
    end)
    #IO.inspect plist
    :ets.new(:counter, [:set, :public, :named_table])
    :ets.insert( :counter,{"spread", 0})
    startTime = System.monotonic_time(:millisecond)
    rand2D(n,plist,startTime)
end

def rand2D(n,plist,startTime) do
   Enum.map(1..(n-1), fn(x) ->
     k=GenServer.call(via_tuple(x),:print)
     xi=Enum.at(k,4)
     yi=Enum.at(k,5)
     Enum.map((x+1)..n, fn(y) ->
       a=GenServer.call(via_tuple(y),:print)
       xj=Enum.at(a,4)
       yj=Enum.at(a,5)
       d=:math.sqrt(:math.pow((xi-xj),2)+:math.pow((yi-yj),2))
       if(d <= 0.1 && x != y) do
          GenServer.cast(via_tuple(x),{:set_neighbour_2d,n,x,plist,y})
          GenServer.cast(via_tuple(y),{:set_neighbour_2d,n,y,plist,x})
      end
    end)
  end)
  start_actor_id=:rand.uniform(n)
  #IO.puts start_actor_id
  start_gossip(n,start_actor_id,"Jajaya",startTime)
end

#-----------------------HANDLE CASTS-------------------------------------#
def handle_cast({:set_neighbour_2d,_n,_id,_plist,ne},state) do
  [_count,neigh,_msg,id,x,y]=state
  list=neigh++[ne]
  {:noreply,[0,list,"",id,x,y]}
end

def handle_cast({:update,rumour},state) do
  [count,list,_msg,id,x,y]=state
  count=count+1
  [{_, spread}] = :ets.lookup(:counter, "spread")
  :ets.insert(:counter, {"spread", spread + 1})
  msg=rumour
  {:noreply,[count,list,msg,id,x,y]}
end

def handle_cast(:send_message,state) do
  [_count,neigh,msg,_id,_x,_y]=state
  if(msg !="" && length(neigh)>0) do
    _= GenServer.cast(via_tuple(Enum.random(neigh)),{:receivemsg,msg,self()})
    {:noreply,state}
  else
    {:noreply,state}
  end
end

def handle_cast({:receivemsg,rumour,_sender}, state) do
   [count,neigh,msg,id,x,y]=state
   count=count+1
   if(count>10) do
     _=remove_neigh(id)
     {:noreply,state}
   else
     if(Enum.at(state,2) != "") do
        {:noreply, [count,neigh,msg,id,x,y]}
    else
      [{_, spread}] = :ets.lookup(:counter, "spread")
      :ets.insert(:counter, {"spread", spread + 1})
      {:noreply, [count,neigh,rumour,id,x,y]}
    end
  end
end

def handle_cast({:remove_neighbour,neighbour_to_remove},state) do
  [count,neigh,msg,id,x,y]=state
  {:noreply,[count,List.delete(neigh,neighbour_to_remove),msg,id,x,y]}
end

def init(list) do
  {:ok,list}
end

def handle_call(:print,_,state) do
  {:reply,state,state}
end

def start_gossip(numNodes,start_actor,rumour,startTime) do
  updateActorwithmessage(start_actor,rumour,startTime)
  spread_the_gossip(numNodes,startTime)
end

def updateActorwithmessage(start_actor,rumour,_startTime) do
  GenServer.cast(via_tuple(start_actor),{:update,rumour})
end

def remove_neigh(id) do
  numNodes=Registry.count(:my_registry)
  for x<- 1..numNodes do
    GenServer.cast(via_tuple(x),{:remove_neighbour,id})
  end
end

def spread_the_gossip(numNodes,startTime) do
  for id <- 1..numNodes do
   GenServer.cast(via_tuple(id),:send_message)
  end
  [{_, spread}] = :ets.lookup(:counter, "spread")
  if (spread/numNodes<0.6) do
      spread_the_gossip(numNodes,startTime)
  else
      endTime = System.monotonic_time(:millisecond) - startTime
      IO.puts "Convergence = #{endTime} milliseconds"
      System.halt(0)
      #IO.puts spread
      #IO.puts "Spread: " <> to_string(spread * 100/(numNodes)) <> " %"
  end
end


def show_state(n) do
  for id <- 1..n do
    GenServer.call(via_tuple(id),:print) |> IO.inspect
  end
end

def start_node(id) do
  GenServer.start_link(__MODULE__,[0,[],"",id,:rand.uniform(),:rand.uniform()], name: via_tuple(id))
end

defp via_tuple(id) do
  {:via, Registry, {:my_registry, id}} #returns pid of a process with that id
end

end
