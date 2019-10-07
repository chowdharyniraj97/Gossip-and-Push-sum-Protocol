#PUSH_SUM_LINE
defmodule Pline do
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
  line(n,plist,starttime)
end


def line(n,plist,starttime) do
   Enum.reduce(1..n, 0, fn x,_->
    _=GenServer.cast(via_tuple(x),{:set_neighbour_line,n,x,plist})
end)
start_actor_id=Enum.random(1..n)
start_pushing(n,start_actor_id,"Jajaya",plist,starttime)
end

#-----------------------------Handle Casts-------------------------------------#
def handle_cast({:set_neighbour_line,n,id,_plist},state) do
  [s,_neigh,_msg,w,s_old,w_old,s_old2,w_old2]=state
  cond do
    id==1 ->
      list=[id+1]
      {:noreply,[s,list,"",w,s_old,w_old,s_old2,w_old2]}
    id==n ->
      list=[id-1]
      {:noreply,[id,list,"",w,s_old,w_old,s_old2,w_old2]}
    true ->
      list=[id-1,id+1]
      {:noreply,[id,list,"",w,s_old,w_old,s_old2,w_old2]}
    end
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

def handle_cast({:send_message,plist,_id},state) do
  [s,neigh,msg,w,s_old,w_old,s_old2,w_old2]=state
  if(msg !="" && length(neigh)>0) do
    s = s/2
    w = w/2
    state=[s,neigh,msg,w,s_old,w_old,s_old2,w_old2]
    randn=Enum.random(neigh)
    GenServer.cast(Enum.at(plist,randn-1),{:receivemsg,msg,self(),s,w,randn-1,plist})
    {:noreply,state}
  else
    {:noreply,state}
  end
end

def handle_cast({:receivemsg,rumour,_sender,s,w,randn,plist}, state) do
   [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]=state
   s_new = s_old + s
   w_new = w_old + w
   if(abs(s_new/w_new - s_old/w_old) < :math.pow(10, -10) && abs(s_old/w_old - s_old2/w_old2) < :math.pow(10, -10) && abs(s_old2/w_old2 - s_old3/w_old3) < :math.pow(10, -10)) do
      remove_neigh_line(randn,plist)
      [{_, spread}] = :ets.lookup(:counter, "spread")
      :ets.insert(:counter, {"spread", spread + 1})
      {:noreply,[s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]}
   #else
      #if(msg != "") do
      #  {:noreply, [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]}
      else
        {:noreply, [s_new,neigh,rumour,w_new,s_old,w_old,s_old2,w_old2]}
    #end
  end
end

def handle_cast({:remove_neighbour,neighbour_to_remove},state) do
  [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3]=state
  {:noreply,[s_old,List.delete(neigh,neighbour_to_remove),msg,w_old,s_old2,w_old2,s_old3,w_old3]}
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
    GenServer.cast(Enum.at(plist,id-1),{:send_message,plist,id})
  end
   [{_, spread}] = :ets.lookup(:counter, "spread")
   if (spread/(numNodes)<0.9) do
      spread_the_gossip(numNodes,plist,starttime)
    else
      endtime=System.monotonic_time(:millisecond)-starttime
      IO.puts "Convergence = #{endtime} milliseconds"
      #IO.puts "spread: " <> to_string(spread * 100/(numNodes-1)) <> " %"
      System.halt(1)
  end
end

def remove_neigh_line(id,plist) do
  cond do
  id=1->  GenServer.cast(Enum.at(plist,(id)),{:remove_neighbour,id})
  id=Registry.count(:my_registry)->  GenServer.cast(Enum.at(plist,id-2),{:remove_neighbour,id})
  true->  GenServer.cast(Enum.at(plist,id),{:remove_neighbour,id})
           GenServer.cast(Enum.at(plist,id-2),{:remove_neighbour,id})
  end
end

def start_node(id) do
  GenServer.start_link(__MODULE__,[id,[],"",1,id,1,id,1], name: via_tuple(id))
end

defp via_tuple(id) do
 {:via, Registry, {:my_registry, id}} #returns pid of a process with that id
 end

end
