//
//  HelloWorldLayer.mm
//  Box2dCar
//
//  Created by bluemol on 7/30/13.
//  Copyright rockyee 2013. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"


enum {
	kTagParentNode = 1,
};

enum {
    CB_GROUND = 1<<0,
	CB_CAR = 1<<2,
	CB_WHEEL = 1<<4
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer() {
    
    CCNode *gameNode;
    b2Body *taxiBody;
    
    b2Body *wheelFront;
    b2Body *wheelRear;
    
    CCSprite *taxiSprite;
    
    bool pressedLeft;
	bool pressedRight;
}


-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		
		self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
		CGSize s = [CCDirector sharedDirector].winSize;
        
        gameNode = [[CCNode alloc] init];
        gameNode.position = ccp(0,0);
        [self addChild:gameNode z:1];
        
        [self initMyPhysics];
		
		// init physics
		//[self initPhysics];
		
		// create reset button
		//[self createMenu];
		
		//Set up sprite
		/*
#if 1
		// Use batch node. Faster
		CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"blocks.png" capacity:100];
		spriteTexture_ = [parent texture];
#else
		// doesn't use batch node. Slower
		spriteTexture_ = [[CCTextureCache sharedTextureCache] addImage:@"blocks.png"];
		CCNode *parent = [CCNode node];
#endif
		[self addChild:parent z:0 tag:kTagParentNode];
		
		
		[self addNewSpriteAtPosition:ccp(s.width/2, s.height/2)];
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Tap screen" fontName:@"Marker Felt" fontSize:32];
		[self addChild:label z:0];
		[label setColor:ccc3(0,0,255)];
		label.position = ccp( s.width/2, s.height-50);
		*/
         
		[self scheduleUpdate];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}	

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
	}];

	// to avoid a retain-cycle with the menuitem and blocks
	__block id copy_self = self;

	// Achievement Menu Item using blocks
	CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
		
		
		GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
		achivementViewController.achievementDelegate = copy_self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:achivementViewController animated:YES];
		
		[achivementViewController release];
	}];
	
	// Leaderboard Menu Item using blocks
	CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
		
		
		GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
		leaderboardViewController.leaderboardDelegate = copy_self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:leaderboardViewController animated:YES];
		
		[leaderboardViewController release];
	}];
	
	CCMenu *menu = [CCMenu menuWithItems:itemAchievement, itemLeaderboard, reset, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width/2, size.height/2)];
	
	
	[self addChild: menu z:-1];	
}


-(void) initMyPhysics
{
    
    CGSize s = [[CCDirector sharedDirector] winSize];
    
    // Create the world
    
    b2Vec2 gravity;
    gravity.Set(0.0f, -20.0f);
    world = new b2World(gravity);
    
    // Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
    
    
    // Create Ground
    
    b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0);
	b2Body *body = world->CreateBody(&groundBodyDef);
    
    
    b2EdgeShape groundBox;
	
	b2FixtureDef groundFixtureDef;
	groundFixtureDef.restitution = 0.0f;
	groundFixtureDef.friction = 10.0f;	//The road has a lot of friction
	groundFixtureDef.filter.categoryBits = CB_GROUND;
	groundFixtureDef.filter.maskBits = CB_CAR | CB_WHEEL;
    
	groundBox.Set(b2Vec2(-s.width/PTM_RATIO,0), b2Vec2(-s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundFixtureDef.shape = &groundBox;
	body->CreateFixture(&groundFixtureDef);
	
	groundBox.Set(b2Vec2(s.width*2/PTM_RATIO,0), b2Vec2(s.width*2/PTM_RATIO,s.height/PTM_RATIO));
	groundFixtureDef.shape = &groundBox;
	body->CreateFixture(&groundFixtureDef);

    b2EdgeShape groundEdge;
    
    groundEdge.Set(b2Vec2(-s.width, 0.0f), b2Vec2(0.0f, 0.0f));
    body->CreateFixture(&groundEdge, 0.0f);
    
    groundEdge.Set(b2Vec2(0.0f, 0.0f), b2Vec2(s.width*0.5/PTM_RATIO, 0.0f));
    body->CreateFixture(&groundEdge, 0.0f);
    
    groundEdge.Set(b2Vec2(s.width*0.5/PTM_RATIO, 0.0f), b2Vec2(s.width/PTM_RATIO, 100/PTM_RATIO));
    body->CreateFixture(&groundEdge, 0.0f);
    
    groundEdge.Set(b2Vec2(s.width/PTM_RATIO, 100/PTM_RATIO), b2Vec2(s.width*2/PTM_RATIO, 0.0f));
    body->CreateFixture(&groundEdge, 0.0f);


}


-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);		
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();
}

-(void) addNewSpriteAtPosition:(CGPoint)p
{
    if (taxiBody == NULL) {
        
        CGSize s = [CCDirector sharedDirector].winSize;

        
        CGPoint taxiPosition = ccp(40, 40);
        
        CCLOG(@"Add sprite to %0.2f x %02.f",p.x,p.y);
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"taxi.plist"];

        float taxiScale = 0.2f;
        
        taxiSprite = [CCSprite spriteWithSpriteFrameName:@"taxi_main.png"];
        taxiSprite.anchorPoint = ccp(0, 0);
        //taxiSprite.position = ccp(p.x, p.y);
        taxiSprite.position = ccp (taxiPosition.x/PTM_RATIO, taxiPosition.y/PTM_RATIO);
        taxiSprite.scale = taxiScale;
        [gameNode addChild:taxiSprite z:100];
        
        // Define the dynamic body.
        //Set up a 1m squared box in the physics world
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        //bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
        bodyDef.position.Set(taxiPosition.x/PTM_RATIO, taxiPosition.y/PTM_RATIO);
        bodyDef.userData = taxiSprite;
        taxiBody = world->CreateBody(&bodyDef);
        
        b2FixtureDef taxiFixtureDef;
        taxiFixtureDef.filter.categoryBits = CB_CAR;
        taxiFixtureDef.filter.maskBits = CB_GROUND;
        taxiFixtureDef.density = 0.5f;
        taxiFixtureDef.friction = 0.25f;
        taxiFixtureDef.restitution = 0.0f;
        
        
        //Polygon
        CGPoint polygonSize = ccp(8.875f * taxiScale,4.218f * taxiScale);
        
        int32 numVerts = 11;
        CGPoint vertexArr[] = { ccp(0.95f, 0.08f), ccp(0.98f, 0.18f), ccp(0.94f, 0.38f), ccp(0.81f, 0.67f), ccp(0.66f, 0.83f),
            ccp(0.53f, 0.95f), ccp(0.38f, 0.94f), ccp(0.24f, 0.8f),  ccp(0.12f, 0.58f), ccp(0.03f, 0.34f),ccp(0.03f, 0.1f)  };
        b2Vec2 vertices[11];
        
        for(int i=0; i<numVerts; i++){
            vertices[i].Set(vertexArr[i].x*polygonSize.x, vertexArr[i].y*polygonSize.y);
        }
        
        b2PolygonShape *taxiShape = new b2PolygonShape();
        
        taxiShape->Set(vertices, numVerts);
        taxiFixtureDef.shape = taxiShape;
        
        taxiBody->CreateFixture(&taxiFixtureDef);
        
        // add wheels
        //CGPoint wheelPosition[] = { ccp(p.x/PTM_RATIO + 16, p.y/PTM_RATIO), ccp(p.x/PTM_RATIO + 43, p.y/PTM_RATIO) };
        //CGPoint wheelPosition[] = { ccp((p.x+16) , p.y), ccp((p.x+43) , p.y) };
        CGPoint wheelPosition[] = { ccp((taxiPosition.x+16) , taxiPosition.y), ccp((taxiPosition.x+43) , taxiPosition.y) };

        
        for(int i=0; i<2; i++){
            
            CGPoint textureSize = ccp(52, 51);
            CGPoint shapeSize = ccp(9,9);
            
            CCSprite *wheelSprite = [CCSprite spriteWithSpriteFrameName:@"taxi_wheel.png"];
            
            wheelSprite.position = ccp(wheelPosition[i].x, wheelPosition[i].y);
            wheelSprite.scaleX = shapeSize.x / textureSize.y * 2;
            wheelSprite.scaleY = shapeSize.y / textureSize.y * 2;
            
            [gameNode addChild:wheelSprite z:100];
            
            b2BodyDef wheelBodyDef;
            wheelBodyDef.type = b2_dynamicBody;
            wheelBodyDef.position.Set(wheelPosition[i].x/PTM_RATIO, wheelPosition[i].y/PTM_RATIO);
            
            wheelBodyDef.userData = wheelSprite;

            b2Body *wheel = world->CreateBody(&wheelBodyDef);


            if (i==0) {
                wheelRear = wheel;
            } else {
                wheelFront = wheel;
            }
            
            wheel->SetTransform(b2Vec2(wheelPosition[i].x/PTM_RATIO, wheelPosition[i].y/PTM_RATIO),3.14159/2);


            b2FixtureDef wheelFixtureDef;
            wheelFixtureDef.filter.categoryBits = CB_WHEEL;
            wheelFixtureDef.filter.maskBits = CB_GROUND;
            wheelFixtureDef.density = 10.0f;
            wheelFixtureDef.friction = 10.0f;
            wheelFixtureDef.restitution = 0.0f;
            

            

            b2CircleShape *wheelCircleShape = new b2CircleShape();
            
            if (i==0) {
                wheelCircleShape->m_radius = shapeSize.x/PTM_RATIO;

            } else {
                wheelCircleShape->m_radius = shapeSize.x/PTM_RATIO;
            }
            
            wheelFixtureDef.shape = wheelCircleShape;
            
            wheel->CreateFixture(&wheelFixtureDef);
            wheel->SetAngularDamping(1.0f);
            
            //Add Joint to connect wheel to the taxi
            b2RevoluteJointDef rjd;
            b2RevoluteJoint* joint;
            
            rjd.Initialize(wheel, taxiBody, b2Vec2(wheelPosition[i].x/PTM_RATIO, wheelPosition[i].y/PTM_RATIO));
            joint = (b2RevoluteJoint*)world->CreateJoint(&rjd);
        }
         

    }

}

/* Press the left side of the screen to drive left, the right to drive right */
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
    
	if(point.x < 240){
		pressedLeft = YES; pressedRight = NO;
	}else if(point.x >= 240){
        //world->SetGravity(b2Vec2(0.0f, 0.5f));
		pressedRight = YES; pressedLeft = NO;
	}
    
    [self addNewSpriteAtPosition:point];
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
	if(point.x < 240){
		pressedLeft = YES; pressedRight = NO;
	}else if(point.x >= 240){
		pressedRight = YES; pressedLeft = NO;
	}
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [touch view]];
	point = [[CCDirector sharedDirector] convertToGL: point];
	
	pressedLeft = NO;
	pressedRight = NO;
    
    world->SetGravity(b2Vec2(0.0f, -20.0f));

}


-(void) update: (ccTime) dt
{

    
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 3;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    

    
    //We apply some counter-torque to steady the car
    if (wheelFront != nil && wheelRear != nil) {
        
        //Set sprite positions by body positions
        for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
        {
            if (b->GetUserData() != NULL) {
                CCSprite *tmp = (CCSprite*)b->GetUserData();
                [tmp setPosition:CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO)];
                tmp.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            }
        }
        
        gameNode.position = ccp(-taxiSprite.position.x + 240, -taxiSprite.position.y + 160);

        if(pressedRight){
            wheelFront->ApplyTorque(-100.0f);
            taxiBody->ApplyTorque(5.0f);
        }else if(pressedLeft){
            wheelRear->ApplyTorque(20.0f);
            taxiBody->ApplyTorque(-5.0f);
        }
    }
}


#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

@end
