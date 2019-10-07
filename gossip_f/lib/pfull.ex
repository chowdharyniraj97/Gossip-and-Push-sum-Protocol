defmodule Pfull do
use GenServer
def fire(n,_top) do
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
    start_pushing(n,start_actor_id,"Jajaya",plist,starttime)
end

def full(n,plist) do
  Enum.reduce(1..n, 0, fn x,_acc->
    GenServer.cast(via_tuple(x),{:set_neighbour,n,x,plist})
  end)
end

def handle_call(:print,state) do
  {:reply,state,state}
end

#---------------------------Handle Casts---------------------------------------#
def handle_cast({:set_neighbour,_n,id,plist},_state) do #setting up neighbours
  [{pid,_val}]=Registry.lookup(:my_registry,id)
  list=List.delete(plist,pid)
  {:noreply,[id,list,"",1,id,1,id,1]}
end

def handle_cast({:update,rumour},state) do
  [s,list,msg,w,s_old,w_old,s_old2,w_old2]=state
  if(msg=="") do
    msg=rumour
    {:noreply,[s,list,msg,w,s_old,w_old,s_old2,w_old2]}
 else
   {:noreply,state}
 end
end

def handle_cast(:send_message,state) do
  [s,neigh,msg,w,s_old,w_old,s_old2,w_old2]=state
  if(msg !="" && length(neigh)>0) do
    s = s/2
    w = w/2
    state=[s,neigh,msg,w,s_old,w_old,s_old2,w_old2]
    GenServer.cast(Enum.random(neigh),{:receivemsg,msg,self(),s,w})
    {:noreply,state}
  else
    {:noreply,state}
  end
end

def handle_cast({:receivemsg,rumour,sender,s,w}, state) do
  [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]=state
  s_new = s_old + s
  w_new = w_old + w
  if(abs(s_new/w_new - s_old/w_old) < :math.pow(10, -10) && abs(s_old/w_old - s_old2/w_old2) < :math.pow(10, -10) && abs(s_old2/w_old2 - s_old3/w_old3) < :math.pow(10, -10)) do
      GenServer.cast(sender, {:remove_neighbor, self()})
      [{_, spread}] = :ets.lookup(:counter, "spread")
      :ets.insert(:counter, {"spread", spread + 1})
      {:noreply,[s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]}
  #else
      #if(msg != "") do
        #{:noreply, [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]}
      else
       {:noreply, [s_new,neigh,rumour,w_new,s_old,w_old,s_old2,w_old2]}
     #end
  end
end

def handle_cast({:remove_neighbor, neighbor}, state) do
  [s,neigh,msg,w,s_old1,w_old1,s_old2,w_old2]=state
  {:noreply,[s,List.delete(neigh,neighbor),msg,w,s_old1,w_old1,s_old2,w_old2]}
end

def init(list) do
  {:ok,list}
end

def start_pushing(numNodes,start_actor,rumour,plist,starttime) do
  updateActorwithmessage(start_actor,rumour)
  spread_the_gossip(numNodes,plist,starttime)
end

def updateActorwithmessage(start_actor,rumour) do
  GenServer.cast(via_tuple(start_actor),{:update,rumour})
end

def spread_the_gossip(numNodes,plist,starttime) do
  for id <- 1..numNodes do
    GenServer.cast(Enum.at(plist,id-1),:send_message)
  end
  [{_, spread}] = :ets.lookup(:counter, "spread")
  if (spread/(numNodes)<0.9) do
      spread_the_gossip(numNodes,plist,starttime)
  else
    endtime=System.monotonic_time(:millisecond)-starttime
    IO.puts "Convergence = #{endtime} milliseconds"
    System.halt(1)
    #IO.puts "spread: " <> to_string(spread * 100/(numNodes-1)) <> " %"
  end
end

def start_node(id) do
  GenServer.start_link(__MODULE__,[id,[],"",1,id,1,id,1], name: via_tuple(id))
end

defp via_tuple(id) do
 {:via, Registry, {:my_registry, id}} #returns pid of a process with that id

end
end
