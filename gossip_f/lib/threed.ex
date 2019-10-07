defmodule Threed do
  def fire(n,_top) do
    n = round(:math.pow(:math.ceil(:math.pow(n,1/3)),3))
    Registry.start_link(name: :my_registry, keys: :unique)
    Enum.map(1..n,fn(x) -> start_node(x) end)
    list=Registry.select(:my_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    plist=Enum.reduce(list,[],fn(x,acc)->
        acc ++ [elem(x,1)]
    end)
    :ets.new(:counter, [:set, :public, :named_table])
    :ets.insert( :counter,{"spread", 0})
    startTime = System.monotonic_time(:millisecond)
    buildTorusTopology(n,plist,startTime)
  end

  def buildTorusTopology(numNodes,plist,startTime) do
        n=numNodes
        cuberoot=round(:math.ceil(:math.pow(numNodes,1/3)))
        numNodes=round(numNodes/cuberoot)
        sqroot= round(Float.ceil(:math.sqrt(numNodes))) #handle for non squarable
        for(i<-1..cuberoot) do
          Enum.map(1..numNodes, fn x->
            a=x+(i-1)*numNodes
            #IO.inspect(a)
            leftNode = if(rem(a-1,sqroot) != 0) do a-1
          else round(sqroot*Float.ceil(a/sqroot)) end
            rightNode = if(rem(a,sqroot) != 0) do a+1
          else (sqroot*round(Float.floor((a-1)/sqroot)))+1 end
            topNode = if(a <= ((sqroot*sqroot - sqroot)+(numNodes*(i-1)))) do a+sqroot
          else rem(a-1,sqroot)+1+(numNodes*(i-1)) end
            bottomNode = if(a > sqroot+(numNodes*(i-1))) do a-sqroot
          else numNodes*(i) - sqroot + rem(a-1,sqroot) + 1 end
          uppNode=if(a+round(:math.pow(sqroot,2)) > n) do
             rem(a+round(:math.pow(sqroot,2)),n)
           else (a+round(:math.pow(sqroot,2))) end
          botNode=if(a<round(:math.pow(sqroot,2))) do
               (a+n-round(:math.pow(sqroot,2)))
             else (a-round(:math.pow(sqroot,2))) end
            list =  [rightNode,leftNode,bottomNode,topNode,uppNode,botNode]
            #IO.inspect (list)
            GenServer.cast(via_tuple(a),{:set_neighbour,n,a,plist,list})
          end)
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
