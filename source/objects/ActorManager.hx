package objects;

import core.Timeline.TimelineEvent;
import core.Level.LevelMetaData;

typedef ActorFactory = TimelineEvent->LevelActor;

class ActorManager
{
    static var registeredActors:Map<String, ActorFactory> = [];
    static var initialized:Bool = false;
    
    // todos os atores do jogo ficam listados aqui, e só aqui
    public static function init()
    {
        if (initialized)
            return;
        initialized = true;
        
        registerActor("pulse_square", e -> new PulseBlock(e.params.x, e.params.y, e.time, e.lead, e.params.duration, e.params.outro));
        // registerActor("laser", e -> new Laser(...));
    }
    
    public static inline function registerActor(id:String, factory:ActorFactory)
        registeredActors.set(id, factory);
        
    public static function createActor(e:TimelineEvent):Null<LevelActor>
    {
        var factory:ActorFactory = registeredActors.get(e.object);
        if (factory == null)
        {
            trace('Actor "${e.object}" não registrado, ignorando.');
            return null;
        }
        
        var actor:LevelActor = factory(e);
        actor.event = e;
        return actor;
    }
    
    public static function createAll(levelData:LevelMetaData):Array<LevelActor>
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
