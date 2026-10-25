package core;

typedef TimelineEvent =
{
    var time:Float; // momento do impacto, em ms
    var object:String;
    var ?lead:Float; // quanto antes (ms) o objeto deve nascer
    var ?params:Dynamic;
}

class Timeline
{
    var events:Array<TimelineEvent> = [];
    var next:Int = 0;
    
    public function new(events:Array<TimelineEvent>)
    {
        this.events = events;
        this.events.sort((a, b) ->
        {
            var d = spawnTime(a) - spawnTime(b);
            return d < 0 ? -1 : (d > 0 ? 1 : 0);
        });
    }
    
    static inline function spawnTime(e:TimelineEvent):Float
        return e.time - (e.lead == null ? 0 : e.lead);
        
    public function update(currentTime:Float, spawn:TimelineEvent->Void)
    {
        while (next < events.length && spawnTime(events[next]) <= currentTime)
        {
            spawn(events[next]);
            next++;
        }
    }
    
    public function reset()
        next = 0;
}
