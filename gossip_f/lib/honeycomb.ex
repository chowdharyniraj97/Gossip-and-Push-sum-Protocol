defmodule Honeycomb do
  use GenServer
  def fire(n,topology) do
    n = round(:math.ceil(:math.pow(n,1/2)))
    n=cond do
      rem(n,2) != 0 -> n+1
      true -> n
    end
    n=round(:math.pow(n,2))
    w=round(:math.pow(n,1/2))
    n=n+w
    Registry.start_link(name: :my_registry, keys: :unique)
    Enum.map(1..n,fn(x) -> start_node(x) end)
    list=Registry.select(:my_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    plist=Enum.reduce(list,[],fn(x,acc)->
        acc ++ [elem(x,1)]
    end)
    :ets.new(:counter, [:set, :public, :named_table])
    :ets.insert( :counter,{"spread", 0})
    startTime = System.monotonic_time(:millisecond)
    case topology do
        "honeycomb" -> honey(n,plist,startTime,w)
        "randhoneycomb" -> honeyrand(n,plist,startTime,w)
    end
  end

  def honeyrand(n,plist,startTime,w)do
    #w = round(:math.pow(n,1/2))
    :ets.new(:c, [:set, :public, :named_table])
    :ets.insert( :c,{"k", 1})
    rand=Enum.random(1..n)
    for i <- 0..w do
      for j <- (i*w)+1..w*(i+1) do
        [{_, k}] = :ets.lookup(:c, "k")
        cond do
        (j == 1 || j==w) && i==0 ->
          neigh = [j+w]++[rand]
          GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
        i==0 ->
          if (rem(j,2)==0) do
            neigh = [j+w]++[j+1]++[rand]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          else
            neigh = [j+w]++[j-1]++[rand]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          end
        i==w && (j==(i*w)+1 || j==w*(i+1)) ->
          neigh = [j-w]++[rand]
          GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
        i==w ->
          if (rem(j,2)==0) do
            neigh = [j-w]++[j+1]++[rand]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          else
            neigh = [j-w]++[j-1]++[rand]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          end
        rem(i,2) != 0 ->
          if (rem(j,2)==0) do
              neigh = [j+w]++[j-w]++[j-1]++[rand]
              GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
            else
              neigh = [j+w]++[j-w]++[j+1]++[rand]
              GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          end
        rem(i,2) == 0 ->
              cond do
              (j==(i*w)+1 || j==w*(i+1)) ->
                neigh = [j+w]++[j-w]++[rand]
                GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
              rem(j,2) != 0 ->
                neigh = [j+w]++[j-w]++[j-1]++[rand]
                GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
              true ->
                neigh = [j+w]++[j-w]++[j+1]++[rand]
                GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
            end
        end
        :ets.insert(:c, {"k", k + 1})
      end
    end
    start_actor_id=:rand.uniform(n)
    start_gossip(n,start_actor_id,"Jajaya",startTime)
  end

  def honey(n,plist,startTime,w)do
    #w = round(:math.pow(n,1/2))
    :ets.new(:c, [:set, :public, :named_table])
    :ets.insert( :c,{"k", 1})
    for i <- 0..w do
      for j <- (i*w)+1..w*(i+1) do
        [{_, k}] = :ets.lookup(:c, "k")
        cond do
        (j == 1 || j==w) && i==0 ->
          neigh = [j+w]
          GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
        i==0 ->
          if (rem(j,2)==0) do
            neigh = [j+w]++[j+1]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          else
            neigh = [j+w]++[j-1]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          end
        i==w && (j==(i*w)+1 || j==w*(i+1)) ->
          neigh = [j-w]
          GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
        i==w ->
          if (rem(j,2)==0) do
            neigh = [j-w]++[j+1]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          else
            neigh = [j-w]++[j-1]
            GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          end
        rem(i,2) != 0 ->
          if (rem(j,2)==0) do
              neigh = [j+w]++[j-w]++[j-1]
              GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
            else
              neigh = [j+w]++[j-w]++[j+1]
              GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
          end
        rem(i,2) == 0 ->
              cond do
              (j==(i*w)+1 || j==w*(i+1)) ->
                neigh = [j+w]++[j-w]
                GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
              rem(j,2) != 0 ->
                neigh = [j+w]++[j-w]++[j-1]
                GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
              true ->
                neigh = [j+w]++[j-w]++[j+1]
                GenServer.cast(via_tuple(k),{:set_neighbour,n,k,plist,neigh})
            end
        end
        :ets.insert(:c, {"k", k + 1})
      end
    end
    start_actor_id=:rand.uniform(n)
    start_gossip(n,start_actor_id,"Jajaya",startTime)
  end

#----------------------------Handle Casts---------------------------------------#
  def handle_cast({:set_neighbour,_n,_id,_plist,ne},state) do
    [_count,neigh,_msg,id]=state
    list=neigh++ne
    {:noreply,[0,list,"",id]}
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
    [count,neigh,msg,_id]=state
    if(msg !="" && length(neigh)>0 && count<10) do
      _= GenServer.cast(via_tuple(Enum.random(neigh)),{:receivemsg,msg,self()})
      {:noreply,state}
    else
      {:noreply,state}
    end
  end

  def handle_cast({:receivemsg,rumour,_sender}, state) do
    [count,neigh,msg,id]=state
    count=count+1
    if(count>10) do
       _=remove_neigh(id)
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
     if (spread/numNodes<0.9) do
        spread_the_gossip(numNodes,startTime)
    else
        endTime = System.monotonic_time(:millisecond) - startTime
        IO.puts "Convergence = #{endTime} milliseconds"
        System.halt(0)
        #IO.puts spread
        #IO.puts "Spread: " <> to_string(spread * 100/(numNodes)) <> " %"
    end
  end

  def start_node(id) do
    GenServer.start_link(__MODULE__,[0,[],"",id], name: via_tuple(id))
  end

  defp via_tuple(id) do
    {:via, Registry, {:my_registry, id}} #returns pid of a process with that id
  end

end
