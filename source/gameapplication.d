module gameapplication;

import std.stdio;
import std.string;
import std.random;
import bindbc.sdl;
import gameobject;
import component;

bool checkCollision(SDL_Rect a, SDL_Rect b) {
    return SDL_HasIntersection(&a, &b) != 0;
}

struct GameApplication {
    string[] mArgs;
    SDL_Window* mWindow = null;
    SDL_Renderer* mRenderer = null;
    bool mGameIsRunning = true;

    // game data
    GameObject player;
    GameObject[] aliens;
    GameObject[] projectiles;

    // assets
    string mCharacterAsset;
    string mInvaderAsset;

    // swarm data (y axis remains fixed)
    int swarmX;
    int swarmY;
    int swarmSpeed;

    // grid layout for alien formation
    int rows = 3;
    int cols = 12;
    int spacingX = 33;
    int spacingY = 33;

    // global alien size variables
    int alienWidth = 32;
    int alienHeight = 32;

    this(string title, string[] args) {
        mArgs = args;
        // here, args[1] is the character asset and args[2] is the invader asset.
        mCharacterAsset = args[1];
        mInvaderAsset   = args[2];

        // create an sdl window.
        mWindow = SDL_CreateWindow(title.toStringz,
                                   SDL_WINDOWPOS_UNDEFINED,
                                   SDL_WINDOWPOS_UNDEFINED,
                                   640, 480,
                                   SDL_WINDOW_SHOWN);
        // create a hardware accelerated renderer.
        mRenderer = SDL_CreateRenderer(mWindow, -1, SDL_RENDERER_ACCELERATED);

        // initialize swarm data.
        swarmX = 30;
        swarmY = 30;
        swarmSpeed = 2;
    }

    ~this() {
        SDL_DestroyRenderer(mRenderer);
        SDL_DestroyWindow(mWindow);
    }

    void SetupScene() {
        // create the player using the character asset.
        player = new GameObject(mRenderer, mCharacterAsset, "");
        // place the player near the bottom center.
        player.mRect.x = 320 - 25;
        player.mRect.y = 400;
        player.mRect.w = 50;
        player.mRect.h = 50;

        // add player movement controller.
        auto controller = new PlayerController();
        controller.mOwner = player;
        player.mComponents ~= controller;

        // create a 12×3 block of aliens with tight spacing.
        aliens.length = rows * cols;
        int index = 0;
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                auto alien = new GameObject(mRenderer, mInvaderAsset, "");
                // store grid position in the alien object.
                alien.row = r;
                alien.col = c;
                // use the global alien size variables.
                alien.mRect.w = alienWidth;
                alien.mRect.h = alienHeight;
                alien.isActive = true;
                aliens[index++] = alien;
            }
        }
    }

    void Input() {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                mGameIsRunning = false;
            } else if (event.type == SDL_KEYDOWN) {
                // when the up arrow key is pressed, fire a bullet from the player.
                if (event.key.keysym.sym == SDLK_UP) {
                    auto proj = new GameObject(mRenderer, "", "");
                    // position projectile at the center-top of the player.
                    proj.mRect.x = player.mRect.x + player.mRect.w / 2 - 5;
                    proj.mRect.y = player.mRect.y - 20;
                    proj.mRect.w = 10;
                    proj.mRect.h = 20;
                    // player projectile: default fromplayer is true.
                    auto projScript = new ProjectileScript();
                    projScript.mOwner = proj;
                    proj.mComponents ~= projScript;
                    projectiles ~= proj;
                }
            }
        }
        // let the player process continuous input (for left/right movement).
        player.Input();
    }

    void Update() {
        moveSwarm();
        player.Update();
        clampPlayerPosition();
        foreach (proj; projectiles) {
            proj.Update();
        }
        alienFire();
        handleCollisions();
        checkGameOverConditions();
    }

    void moveSwarm() {
        // move the formation horizontally.
        swarmX += swarmSpeed;

        int leftEdge  = swarmX;
        int rightEdge = swarmX + (cols - 1) * spacingX + alienWidth;

        // check if the formation has hit a horizontal boundary.
        if (rightEdge > 640) {
            swarmSpeed = -swarmSpeed;
            swarmX = 640 - ((cols - 1) * spacingX + alienWidth);
        } else if (leftEdge < 0) {
            swarmSpeed = -swarmSpeed;
            swarmX = 0;
        }

        // update each alien's position.
        foreach (alien; aliens) {
            if (!alien.isActive) continue;
            alien.mRect.x = swarmX + alien.col * spacingX;
            alien.mRect.y = swarmY + alien.row * spacingY;
        }
    }

    void clampPlayerPosition() {
        // ensure the player's x position is within the window.
        if (player.mRect.x < 0)
            player.mRect.x = 0;
        else if (player.mRect.x + player.mRect.w > 640)
            player.mRect.x = 640 - player.mRect.w;
    }

    void alienFire() {
        // increase frequency: 2% chance per frame.
        if (uniform(0.0, 1.0) < 0.02) {
            // build a list of active aliens.
            GameObject[] activeAliens;
            foreach (alien; aliens) {
                if (alien.isActive)
                    activeAliens ~= alien;
            }
            if (activeAliens.length > 0) {
                int idx = cast(int) uniform(0, activeAliens.length);
                auto shooter = activeAliens[idx];

                // create an alien bullet (projectile).
                auto proj = new GameObject(mRenderer, "", "");
                // position the bullet at the bottom-center of the shooting alien.
                proj.mRect.x = shooter.mRect.x + shooter.mRect.w / 2 - 5;
                proj.mRect.y = shooter.mRect.y + shooter.mRect.h;
                proj.mRect.w = 10;
                proj.mRect.h = 20;
                // mark this projectile as not from the player.
                proj.fromPlayer = false;
                // use an alienprojectilescript which moves the bullet downward.
                auto projScript = new AlienProjectileScript();
                projScript.mOwner = proj;
                proj.mComponents ~= projScript;
                projectiles ~= proj;
            }
        }
    }

    void handleCollisions() {
        // process collisions for player-fired projectiles.
        for (int i = cast(int)projectiles.length - 1; i >= 0; i--) {
            if (!projectiles[i].fromPlayer)
                continue;
            auto proj = projectiles[i];
            bool collided = false;
            foreach (alien; aliens) {
                if (!alien.isActive) continue;
                if (checkCollision(proj.mRect, alien.mRect)) {
                    // mark the alien as inactive.
                    alien.isActive = false;
                    // remove the projectile.
                    projectiles = projectiles[0 .. i] ~ projectiles[i + 1 .. $];
                    collided = true;
                    break;
                }
            }
            if (collided)
                continue;
        }
    }

    void checkGameOverConditions() {
        // check if the player is hit by an alien bullet.
        foreach (proj; projectiles) {
            if (!proj.fromPlayer && checkCollision(proj.mRect, player.mRect)) {
                SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "you lost", "you were hit by an alien bullet!", mWindow);
                mGameIsRunning = false;
                return;
            }
        }
        // check if all aliens are inactive.
        bool anyAlienActive = false;
        foreach (alien; aliens) {
            if (alien.isActive) {
                anyAlienActive = true;
                break;
            }
        }
        if (!anyAlienActive) {
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, "victory", "you won! all aliens have been killed.", mWindow);
            mGameIsRunning = false;
        }
    }

    void Render() {
        SDL_SetRenderDrawColor(mRenderer, 100, 190, 255, SDL_ALPHA_OPAQUE);
        SDL_RenderClear(mRenderer);

        // render the player.
        player.Render(mRenderer);

        // render active aliens.
        foreach (alien; aliens) {
            if (alien.isActive)
                alien.Render(mRenderer);
        }

        // render projectiles.
        foreach (proj; projectiles) {
            proj.Render(mRenderer);
        }

        SDL_RenderPresent(mRenderer);
    }

    void AdvanceFrame() {
        Input();
        Update();
        Render();
        SDL_Delay(16);
    }

    void RunLoop() {
        SetupScene();
        while (mGameIsRunning) {
            AdvanceFrame();
        }
    }
}
