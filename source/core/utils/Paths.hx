package core.utils;

import haxe.io.Path;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;

class Paths
{
    static final SCHEMES:Map<String, String> = ["embed" => "assets/embed/", "builtin" => "assets/embed/music/"];
    
    // só é esquema se for um dos conhecidos: "C:\x.ogg" e "audio.ogg" ficam sem esquema
    public static function split(ref:String):{scheme:Null<String>, path:String}
    {
        var i = ref.indexOf(":");
        if (i > 0)
        {
            var s = ref.substr(0, i);
            if (SCHEMES.exists(s))
                return {scheme: s, path: ref.substr(i + 1)};
        }
        return {scheme: null, path: ref};
    }
    
    public static function normalizePath(ref:String):String
    {
        var p = split(ref);
        return p.scheme == null ? p.path : SCHEMES.get(p.scheme) + p.path;
    }
    
    // o que o level diz; vazio cai na convenção
    public static function songRef(songFilename:Null<String>):String
        return (songFilename == null || songFilename == "") ? "audio.ogg" : songFilename;
        
    // onde o jogo vai procurar essa referência; serve para o trace de erro
    public static function resolve(ref:String, levelDir:String):String
    {
        var p = split(ref);
        return p.scheme != null ? normalizePath(ref) : Path.join([levelDir, p.path]);
    }
    
    public static function loadSong(ref:String, levelDir:String):Null<Sound>
    {
        var p = split(ref);
        
        if (p.scheme != null)
        {
            var id = normalizePath(ref);
            // sem filtrar por tipo: dependendo do project.xml o .ogg é registrado como SOUND ou MUSIC
            return OpenFlAssets.exists(id) ? OpenFlAssets.getSound(id) : null;
        }
        
        if (levelDir == "")
            return null; // level que ainda não foi salvo não tem pasta
            
        var file = Path.join([levelDir, p.path]);
        return FileSystem.exists(file) ? Sound.fromFile(file) : null;
    }
}
