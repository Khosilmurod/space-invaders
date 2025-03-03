import std.stdio;
import core.stdc.stdlib;
import gameapplication;

// void main(string[] args)
// {
//     if(args.length < 3){
//         writeln("usage: dub -- \"./assets/images/player.bmp\" \"./assets/images/alien.bmp\"");
//         exit(1);
//     } else {
//         writeln("Starting with args:\n", args);
//     }

//     // create and run the game application.
//     GameApplication app = GameApplication("Game Template", args);
//     app.RunLoop();
// }

import std.stdio;
import core.stdc.stdlib;
import gameapplication;

void main(string[] args)
{
    string[] finalArgs = ["dummy", "./media/knight.bmp", "./media/alien.bmp"];
    writeln("starting with default paths:");
    writeln(finalArgs);
    
    // create and run the game application.
    GameApplication app = GameApplication("Game Template", finalArgs);
    app.RunLoop();
}
