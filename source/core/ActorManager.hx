package core;

import objects.PulseBlock;
import core.Timeline.TimelineEvent;
import core.level.Level.LevelData;

typedef ActorFactory = TimelineEvent->LevelActor;

// NOVO
enum EventCategory
{
    Obstacle;
    Map;
}

// NOVO
typedef ActorEntry =
{
    var factory:ActorFactory;
    var category:EventCategory;
}

class ActorManager
{
    static var registeredActors:Map<String, ActorEntry> = []; // MUDOU o tipo
    static var initialized:Bool = false;
    
    public static function init()
    {
        if (initialized)
            return;
        initialized = true;
        
        registerActor("pulse_square", e -> new PulseBlock(e.params.x, e.params.y, e.time, e.lead, e.params.duration, e.params.outro));
    }
    
    public static inline function registerActor(id:String, factory:ActorFactory, category:EventCategory = Obstacle)
        registeredActors.set(id, {factory: factory, category: category});
        
    public static function categoryOf(id:String):Null<EventCategory>
    {
        var entry = registeredActors.get(id);
        return entry == null ? null : entry.category;
    }
    
    public static function createActor(e:TimelineEvent):Null<LevelActor>
    {
        var entry = registeredActors.get(e.object); // MUDOU
        if (entry == null)
        {
            trace('Actor "${e.object}" não registrado, ignorando.');
            return null;
        }
        
        var actor:LevelActor = entry.factory(e); // MUDOU
        actor.event = e;
        return actor;
    }
    
    public static function createAll(levelData:LevelData):Array<LevelActor>
    {
        var actors:Array<LevelActor> = [];
        for (e in levelData.events)
        {
            var actor = createActor(e);
            if (actor != null)
                actors.push(actor);
        }
        return actors;
    }
}
