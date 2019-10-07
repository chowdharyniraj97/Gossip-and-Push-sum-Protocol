defmodule Line do
 use GenServer

 def fire(n,_topology) do
    starttime=System.monotonic_time(:millisecond)
    Registry.start_link(name: :my_registry, keys: :unique)
    Enum.reduce(1..n,0,fn(x,_acc)-> start_node(x) end)
    list=Registry.select(:my_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    plist=Enum.reduce(list,[],fn(x,acc)->
        acc ++ [elem(x,1)]
    end)
    :ets.new(:counter, [:set, :public, :named_table])
    :ets.insert( :counter,{"spread", 0})
    line(n,plist,starttime)
end

def line(n,plist,starttime) do
  Enum.reduce(1..n, 0, fn x,_->
    GenServer.cast(via_tuple(x),{:set_neighbour_line,n,x,plist})
  end)
  start_actor_id=:rand.uniform(n)
  start_gossip(n,start_actor_id,"Jajaya",starttime)
end

#----------------------------Handle Casts-------------------------------------#
def handle_cast({:set_neighbour_line,n,id,_plist},_state) do
  cond do
  id==1 ->
    list=[id+1]
    {:noreply,[0,list,"",id]}
  id==n ->
   list=[id-1]
   {:noreply,[0,list,"",id]}
  true ->
    list=[id-1,id+1]
    {:noreply,[0,list,"",id]}
  end
end

def handle_cast({:update,rumour},state) do
    [count,list,_msg,id]=state
    count=count+1
    [{_, spread}] = :ets.lookup(:counter, "spread")
    :ets.insert(:counter, {"spread", spread + 1})
    msg=rumour
    {:noreply,[count,list,msg,id]}
 end

def handle_cast(:send_message,state) do
  [_count,neigh,msg,_id]=state
  if(msg !="" && length(neigh)>0) do
    GenServer.cast(via_tuple(Enum.random(neigh)),{:receivemsg,msg,self()})
    {:noreply,state}
  else
    {:noreply,state}
  end
end

def handle_cast({:receivemsg,rumour,_sender}, state) do
  [count,neigh,msg,id]=state
  count=count+1
  if(count>=10) do
     remove_neigh_line(id)
     {:noreply,state}
  else
    if(Enum.at(state,2) != "") do
        {:noreply, [count,neigh,msg,id]}
    else
      [{_, spread}] = :ets.lookup(:counter, "spread")
      :ets.insert(:counter, {"spread", spread + 1})
       {:noreply, [count,neigh,rumour,id]}
    end
  end
end

def handle_cast({:remove_neighbour,neighbour_to_remove},state) do
  [count,neigh,msg,id]=state
  {:noreply,[count,List.delete(neigh,neighbour_to_remove),msg,id]}
end

def init(list) do
  {:ok,list}
end

def handle_call(:print,_,state) do
  {:reply,state,state}
end

def start_gossip(numNodes,start_actor,rumour,starttime) do
  updateActorwithmessage(start_actor,rumour)
  spread_the_gossip(numNodes,starttime)
end


def updateActorwithmessage(start_actor,rumour) do
  GenServer.cast(via_tuple(start_actor),{:update,rumour})
end

def remove_neigh_line(id) do
  cond do
    id=1->  GenServer.cast(via_tuple(id+1),{:remove_neighbour,id})

    id=Registry.count(:my_registry)->  GenServer.cast(via_tuple(id-1),{:remove_neighbour,id})

    true->  GenServer.cast(via_tuple(id+1),{:remove_neighbour,id})
           GenServer.cast(via_tuple(id-1),{:remove_neighbour,id})
  end
end

def spread_the_gossip(numNodes,starttime) do
  for id <- 1..numNodes do
    GenServer.cast(via_tuple(id),:send_message)
  end
  [{_, spread}] = :ets.lookup(:counter, "spread")
  if (spread/numNodes<0.6) do
     spread_the_gossip(numNodes,starttime)
  else
    endtime=System.monotonic_time(:millisecond)-starttime
    IO.puts "Convergence = #{endtime} milliseconds"
    System.halt(1)
    #IO.puts "spread: " <> to_string(spread * 100/(numNodes)) <> " %"
  end
end

def show_state(n) do
   for id <- 1..n do
      GenServer.call(via_tuple(id),:print) |> IO.inspect
   end
end

def start_node(id) do
  GenServer.start_link(__MODULE__,[0,[],"",id], name: via_tuple(id))
end

 defp via_tuple(id) do
 {:via, Registry, {:my_registry, id}} #returns pid of a process with that id
 end
end
