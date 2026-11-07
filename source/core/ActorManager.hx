package core;

import objects.BulletEmitter;
import flixel.FlxG;
import objects.PulseBlock;
import core.Timeline.TimelineEvent;
import core.level.Level.LevelData;

typedef ActorFactory = TimelineEvent->LevelActor;

enum EventCategory
{
    Obstacle;
    Map;
}

enum FieldKind
{
    Number; // time, lead, duration...
    Checkbox; // randomX, randomY
}

// onde o valor do campo mora
enum FieldTarget
{
    Params; // selectedEvent.params.<key>
    Root; // selectedEvent.<key>, tipo time e lead
}

typedef FieldDef =
{
    var key:String;
    var label:String;
    var kind:FieldKind;
    var ?target:FieldTarget; // se omitido, é Params
    var ?step:Float; // quanto o stepper anda (padrão 10)
    var ?active:Bool;
    var ?defaultValue:Dynamic; // usado quando o campo não existe no evento
    var ?min:Float; // menor valor do stepper (padrão 0)
    var ?decimals:Int; // casas decimais exibidas (padrão 0)
}

typedef ActorEntry =
{
    var factory:ActorFactory;
    var category:EventCategory;
    var fields:Array<FieldDef>;
}

class ActorManager
{
    static var registeredActors:Map<String, ActorEntry> = [];
    static var initialized:Bool = false;
    
    public static var randomizePositions:Bool = true;
    
    static inline var RANDOM_MARGIN:Float = 64;
    
    public static function init()
    {
        if (initialized)
            return;
        initialized = true;
        
        PulseBlock.selfRegister();
        BulletEmitter.selfRegister();
    }
    
    public static function getActorNames():Array<String>
    {
        final keys:Array<String> = [];
        for (k => _ in registeredActors)
            keys.push(k);
        keys.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
        return keys;
    }
    
    static function paramOf(e:TimelineEvent, key:String):Dynamic
        return e.params == null ? null : Reflect.field(e.params, key);
        
    public static function posX(e:TimelineEvent):Float
    {
        if (randomizePositions && paramOf(e, "randomX") == true)
            return FlxG.random.float(RANDOM_MARGIN, FlxG.width - RANDOM_MARGIN);
        return paramOf(e, "x") ?? FlxG.width * 0.5;
    }
    
    public static function posY(e:TimelineEvent):Float
    {
        if (randomizePositions && paramOf(e, "randomY") == true)
            return FlxG.random.float(RANDOM_MARGIN, FlxG.height - RANDOM_MARGIN);
        return paramOf(e, "y") ?? FlxG.height * 0.5;
    }
    
    // monta o params de um evento novo a partir dos defaultValue do tipo
    public static function defaultParams(id:String):Dynamic
    {
        var params:Dynamic = {};
        for (f in fieldsOf(id))
            Reflect.setField(params, f.key, f.defaultValue);
        return params;
    }
    
    public static inline function registerActor(id:String, factory:ActorFactory, category:EventCategory = Obstacle, fields:Array<FieldDef> = null)
        registeredActors.set(id, {factory: factory, category: category, fields: fields ?? []});
        
    public static inline function registerMapEvent(id:String, fields:Array<FieldDef>)
        registeredActors.set(id, {factory: null, category: Map, fields: fields});
        
    public static function categoryOf(id:String):Null<EventCategory>
    {
        var entry = registeredActors.get(id);
        return entry == null ? null : entry.category;
    }
    
    public static function createActor(e:TimelineEvent):Null<LevelActor>
    {
        var entry = registeredActors.get(e.object);
        if (entry == null)
        {
            trace('Actor "${e.object}" não registrado, ignorando.');
            return null;
        }
        
        if (entry.factory == null)
            return null;
            
        var actor:LevelActor = entry.factory(e);
        actor.event = e;
        return actor;
    }
    
    public static function num(e:TimelineEvent, key:String, def:Float):Float
    {
        var v:Dynamic = paramOf(e, key);
        return v == null ? def : v;
    }
    
    public static function namesOf(category:EventCategory):Array<String>
    {
        var names:Array<String> = [];
        for (id => entry in registeredActors)
            if (entry.category == category)
                names.push(id);
        names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
        return names;
    }
    
    public static function fieldsOf(id:String):Array<FieldDef>
    {
        var entry = registeredActors.get(id);
        return entry == null ? [] : entry.fields;
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
