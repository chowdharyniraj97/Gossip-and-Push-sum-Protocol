#Push_sum_2d
defmodule Ptwod do
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
     xi=Enum.at(k,8)
     yi=Enum.at(k,9)
     Enum.map((x+1)..n, fn(y) ->
       a=GenServer.call(via_tuple(y),:print)
       xj=Enum.at(a,8)
       yj=Enum.at(a,9)
       d=:math.sqrt(:math.pow((xi-xj),2)+:math.pow((yi-yj),2))
       if(d <= 0.1 && x != y) do
          GenServer.cast(via_tuple(x),{:set_neighbour_2d,n,x,plist,y})
          GenServer.cast(via_tuple(y),{:set_neighbour_2d,n,y,plist,x})
      end
    end)
  end)
  start_actor_id=:rand.uniform(n)
  #IO.puts start_actor_id
  start_gossip(n,start_actor_id,"Jajaya",startTime,plist)

end

#-----------------------HANDLE CASTS-------------------------------------#
def handle_cast({:set_neighbour_2d,_n,_id,_plist,ne},state) do
  [s,neigh,_msg,w,s_old,w_old,s_old2,w_old2,x,y]=state
  list=neigh++[ne]
  {:noreply,[s,list,"",w,s_old,w_old,s_old2,w_old2,x,y]}
end

def handle_cast({:update,rumour},state) do
  [s,neigh,_msg,w,s_old,w_old,s_old2,w_old2,x,y]=state
  msg=rumour
  {:noreply,[s,neigh,msg,w,s_old,w_old,s_old2,w_old2,x,y]}
end

def handle_cast({:send_message,plist,_id},state) do
  [s,neigh,msg,w,s_old,w_old,s_old2,w_old2,x,y]=state
  if(msg !="" && length(neigh)>0) do
    s = s/2
    w = w/2

  state=[s,neigh,msg,w,s_old,w_old,s_old2,w_old2,x,y]
  randn=Enum.random(neigh)
  GenServer.cast(Enum.at(plist,randn-1),{:receivemsg,msg,self(),s,w,randn-1,plist})
  {:noreply,state}
  else
    {:noreply,state}
  end
end

def handle_cast({:receivemsg,rumour,_sender,s,w,randn,plist}, state) do
  [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3,x,y]=state
   s_new = s_old + s
   w_new = w_old + w
   if(abs(s_new/w_new - s_old/w_old) < :math.pow(10, -10) && abs(s_old/w_old - s_old2/w_old2) < :math.pow(10, -10) && abs(s_old2/w_old2 - s_old3/w_old3) < :math.pow(10, -10)) do
      remove_neigh(randn,plist)
      [{_, spread}] = :ets.lookup(:counter, "spread")
      :ets.insert(:counter, {"spread", spread + 1})
      {:noreply,[s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3,x,y]}
  else
      #if(msg != "") do
        #{:noreply, [s_old,neigh,msg,w_old,s_old2,w_old2,s_old3,w_old3,x,y]}
      #else
       {:noreply, [s_new,neigh,rumour,w_new,s_old,w_old,s_old2,w_old2,x,y]}
    #end
  end
end

def handle_cast({:remove_neighbor, neighbor}, state) do
  [s,neigh,msg,w,s_old1,w_old1,s_old2,w_old2,x,y]=state
  {:noreply,[s,List.delete(neigh,neighbor),msg,w,s_old1,w_old1,s_old2,w_old2,x,y]}
end

def init(list) do
  {:ok,list}
end

def handle_call(:print,_,state) do
  {:reply,state,state}
end

def start_gossip(numNodes,start_actor,rumour,startTime,plist) do
  updateActorwithmessage(start_actor,rumour,startTime)
  spread_the_gossip(numNodes,plist,startTime)
end

def updateActorwithmessage(start_actor,rumour,_startTime) do
  GenServer.cast(via_tuple(start_actor),{:update,rumour})
end

def remove_neigh(id,plist) do
  numNodes=Registry.count(:my_registry)
  for x<- 1..numNodes do
    GenServer.cast(Enum.at(plist,x-1),{:remove_neighbor,id})
  end
end

def spread_the_gossip(numNodes,plist,starttime) do
  for id <- 1..numNodes do
    GenServer.cast(Enum.at(plist,id-1),{:send_message,plist,id})
  end
  [{_, spread}] = :ets.lookup(:counter, "spread")
  if (spread/numNodes<0.4) do
     spread_the_gossip(numNodes,plist,starttime)
  else
      endTime = System.monotonic_time(:millisecond) - starttime
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
  GenServer.start_link(__MODULE__,[id,[],"",1,id,1,id,1,:rand.uniform(),:rand.uniform()], name: via_tuple(id))
end

defp via_tuple(id) do
  {:via, Registry, {:my_registry, id}} #returns pid of a process with that id
end

end
