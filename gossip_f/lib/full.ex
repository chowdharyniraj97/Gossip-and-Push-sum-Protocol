defmodule Full do
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
   full(n,plist)
   start_actor_id=Enum.random(1..n)
   start_gossip(n,start_actor_id,"Jajaya",starttime)
end

def full(n,plist) do
  Enum.reduce(1..n, 0, fn x,_acc->
      GenServer.cast(via_tuple(x),{:set_neighbour,n,x,plist})
  end)
end

#--------------------Handle Casts--------------------------------------------#
def handle_cast({:set_neighbour,_n,id,plist},_state) do #setting up neighbours
    [{pid,_val}]=Registry.lookup(:my_registry,id)
    list=List.delete(plist,pid)
    {:noreply,[0,list,"",id]}
end

def handle_cast({:update,rumour},state) do
  [count,list,msg,id]=state
  if(msg=="") do
      msg=rumour
      {:noreply,[count,list,msg,id]}
  else
      {:noreply,state}
  end
end

def handle_cast(:send_message,state) do
  [count,neigh,msg,id]=state
  if(msg !="" && length(neigh)>0 && count<10) do
      GenServer.cast(Enum.random(neigh),{:receivemsg,msg,via_tuple(id)})
      {:noreply,state}
  else
      {:noreply,state}
  end
end

def handle_cast({:receivemsg,rumour,_sender}, state) do
  [count,neigh,msg,id]=state
  count=count+1
  state=[count,neigh,msg,id]
  if(count>10) do
    _=remove_neigh(self())
    {:noreply,state}
  else
    if(msg != "") do
        {:noreply, state}
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

def remove_neigh(rmv_pid) do
  for id <- 1..Registry.count(:my_registry) do
    if(via_tuple(id)!=rmv_pid) do
      GenServer.cast(via_tuple(id),{:remove_neighbour,rmv_pid})
      end
    end
  end

def spread_the_gossip(numNodes,starttime) do
  for id <- 1..numNodes do
    GenServer.cast(via_tuple(id),:send_message)
  end
  [{_, spread}] = :ets.lookup(:counter, "spread")
  if (spread/(numNodes-1)<0.9) do
    spread_the_gossip(numNodes,starttime)
  else
    endtime=System.monotonic_time(:millisecond)-starttime
    IO.puts "Convergence = #{endtime} milliseconds"
    #IO.puts "spread: " <> to_string(spread * 100/(numNodes-1)) <> " %"
    System.halt(1)
  end
end

def start_node(id) do
  GenServer.start_link(__MODULE__,[0,[],"",id], name: via_tuple(id))
end

 defp via_tuple(id) do
   {:via, Registry, {:my_registry, id}} #returns pid of a process with that id
 end
end
