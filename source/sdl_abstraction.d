module sdl_abstraction;

import std.stdio, std.string;
import bindbc.sdl;
import bindbc.loader.sharedlib;

const SDLSupport ret;

shared static this() {
    version(Windows) {
        writeln("Searching for SDL on Windows");
        ret = loadSDL("SDL2.dll");
    }
    version(OSX) {
        writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux) {
        writeln("Searching for SDL on Linux");
        ret = loadSDL();
    }
    if(ret != sdlSupport) {
        writeln("Error loading SDL library");
    }
    if(ret == SDLSupport.noLibrary) {
        writeln("No SDL library found");
    }
    if(ret == SDLSupport.badLibrary) {
        writeln("Error: badLibrary, missing symbols?");
    }
    if(SDL_Init(SDL_INIT_EVERYTHING) != 0) {
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }
}

shared static ~this() {
    SDL_Quit();
    writeln("Ending application--good bye!");
}
