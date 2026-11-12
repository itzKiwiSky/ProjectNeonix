package core;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
#end

class ActorAutoRegisterMacro
{
    // em tempo de compilação, gera uma chamada Classe.selfRegister() para cada classe do pacote que tenha esse método
    public static macro function run(pack:String):Expr
    {
        var calls:Array<Expr> = [];
        var dir = pack.split(".").join("/");
        
        for (cp in Context.getClassPath())
        {
            var folder = Path.addTrailingSlash(cp) + dir;
            if (!FileSystem.exists(folder) || !FileSystem.isDirectory(folder))
                continue;
                
            for (file in FileSystem.readDirectory(folder))
            {
                if (!StringTools.endsWith(file, ".hx"))
                    continue;
                    
                var module = pack + "." + file.substr(0, file.length - 3);
                for (t in Context.getModule(module))
                {
                    switch (t)
                    {
                        case TInst(ref, _):
                            var cls = ref.get();
                            if (cls.module != module || cls.isPrivate)
                                continue;
                            for (f in cls.statics.get())
                                if (f.name == "selfRegister" && f.isPublic)
                                    calls.push(macro $p{cls.pack.concat([cls.name])}.selfRegister());
                        case _:
                    }
                }
            }
        }
        return macro $b{calls};
    }
}
