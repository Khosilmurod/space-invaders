module gameobject;

import std.stdio;
import std.string : toStringz;
import bindbc.sdl;
import component;

class GameObject {
    // components attached to this object.
    IComponent[] mComponents;

    // each object can have a texture and a rectangle.
    SDL_Texture* mTexture;
    SDL_Rect mRect;

    // grid and state info for aliens:
    int row;
    int col;
    bool isActive;

    // new field to indicate if this object is a player projectile.
    bool fromPlayer = true;

    this(SDL_Renderer* renderer, string bitmapFilePath, string jsonFilePath) {
        writeln("loading asset: ", bitmapFilePath);
        // load the texture if an asset path is provided.
        if (bitmapFilePath.length > 0) {
            auto surface = SDL_LoadBMP(toStringz(bitmapFilePath));
            if (surface is null) {
                writeln("error loading bitmap: ", bitmapFilePath);
                mTexture = null;
            } else {
                mTexture = SDL_CreateTextureFromSurface(renderer, surface);
                SDL_FreeSurface(surface);
            }
        } else {
            mTexture = null;
        }
        // set default rectangle values.
        mRect.x = 50;
        mRect.y = 50;
        mRect.w = 100;
        mRect.h = 100;
        // initialize grid and state info.
        row = 0;
        col = 0;
        isActive = true;
        fromPlayer = true;
    }

    void Input() {
        foreach (component; mComponents) {
            component.input();
        }
    }

    void Update() {
        foreach (component; mComponents) {
            component.update();
        }
    }

    void Render(SDL_Renderer* renderer) {
        if (!isActive)
            return;
        if (mTexture !is null) {
            SDL_RenderCopy(renderer, mTexture, null, &mRect);
        } else {
            SDL_SetRenderDrawColor(renderer, 255, 0, 0, SDL_ALPHA_OPAQUE);
            SDL_RenderFillRect(renderer, &mRect);
        }
    }
}
