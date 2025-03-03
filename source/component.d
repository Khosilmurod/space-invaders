module component;

import bindbc.sdl;
import gameobject;

abstract class IComponent {
    GameObject mOwner;
    void input() {}
    void update() {}
}

class PlayerController : IComponent {
    int speed = 5;
    override void update() {
        auto state = SDL_GetKeyboardState(null);
        if (state[SDL_SCANCODE_LEFT] != 0) {
            mOwner.mRect.x -= speed;
        }
        if (state[SDL_SCANCODE_RIGHT] != 0) {
            mOwner.mRect.x += speed;
        }
    }
}

class ProjectileScript : IComponent {
    int speed = 7;
    override void update() {
        // shoot the bullet
        mOwner.mRect.y -= speed;
    }
}

class AlienProjectileScript : IComponent {
    int speed = 7;
    override void update() {
        // drop the bullet
        mOwner.mRect.y += speed;
    }
}