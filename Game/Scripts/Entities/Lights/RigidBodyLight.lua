Script.ReloadScript( "Scripts/Entities/Physics/BasicEntity.lua" );

-- Basic entity
RigidBodyLight = 
{
	Properties = 
	{
		Physics = 
		{
			bRigidBodyActive = 1,
			bActivateOnDamage = 0,
			bResting = 1, -- If rigid body is originally in resting state.
			bCanBreakOthers = 0,
			Simulation =
			{
				max_time_step = 0.02,
				sleep_speed = 0.04,
				damping = 0,
				bFixedDamping = 0,
				bUseSimpleSolver = 0,
			},
			Buoyancy=
			{
				water_density = 1000,
				water_damping = 0,
				water_resistance = 1000,	
			},
		},
	},
	
	PropertiesInstance = 
	{
	  bTurnedOn = 1,
		LightProperties_Base = 
		{
			bUseThisLight = 1,
			Radius = 10,
			vOffset					= {x=0, y=0, z=0},
			vDirection			= {x=0, y=1, z=0},
			Style =
			{
				fCoronaScale = 1,
				fCoronaDistSizeFactor = 1,
				fCoronaDistIntensityFactor = 1,
				nLightStyle = 0,
			},
			Projector =
			{
				texture_Texture = "",
				bProjectInAllDirs = 0,
				fProjectorFov = 90,
				fProjectorNearPlane = 0,
			},
			Color = 
			{
				clrDiffuse = { x=1,y=1,z=1 },
				fDiffuseMultiplier = 1,
				fSpecularMultiplier = 1,
				fHDRDynamic = 0,		-- -1=darker..0=normal..1=brighter
			},
			Options = 
			{
				bCastShadow = 0,
				bIgnoreGeomCaster = 0,
				bAffectsThisAreaOnly = 1,
				bUsedInRealTime=1,
				bFakeLight=0,
				bDeferredLight = 0,
        nViewDistRatio = 100,
        nGlowSubmatId = 0,
			},
			Test = 
			{
				bFillLight=0,
				bNegativeLight=0,
			},
		},
		
		LightProperties_Destroyed = 
		{
			bUseThisLight = 0,
			Radius = 10,
			vOffset					= {x=0, y=0, z=0},
			vDirection			= {x=0, y=1, z=0},
			Style =
			{
				fCoronaScale = 1,
				fCoronaDistSizeFactor = 1,
				fCoronaDistIntensityFactor = 1,
				nLightStyle = 0,
			},
			Projector =
			{
				texture_Texture = "",
				bProjectInAllDirs = 0,
				fProjectorFov = 90,
				fProjectorNearPlane = 0,
			},
			Color = 
			{
				clrDiffuse = { x=1,y=1,z=1 },
				fDiffuseMultiplier = 1,
				fSpecularMultiplier = 1,
				fHDRDynamic = 0,		-- -1=darker..0=normal..1=brighter
			},
			Options = 
			{
				bCastShadow = 0,
				bIgnoreGeomCaster = 0,
				bAffectsThisAreaOnly = 1,
				bUsedInRealTime=1,
				bFakeLight=0,
				bDeferredLight = 0,
        nViewDistRatio = 100,
			},
			Test = 
			{
				bFillLight=0,
				bNegativeLight=0,
			},
		},
	},
	
	
	_LightTable = {},
	lightSlot = -1,
	materialIsCloned = false,
	
		Editor=
	{
		Icon = "Light.bmp",
		IconOnTop=1,
	},
}

local Physics_DX9MP_Simple = {
	bRigidBodyActive = 0,
	bActivateOnDamage = 0,
	bResting = 1, -- If rigid body is originally in resting state.
	Simulation =
	{
		max_time_step = 0.02,
		sleep_speed = 0.04,
		damping = 0,
		bFixedDamping = 0,
		bUseSimpleSolver = 0,
	},
	Buoyancy=
	{
		water_density = 1000,
		water_damping = 0,
		water_resistance = 1000,	
	},
	
}

MakeDerivedEntity( RigidBodyLight, BasicEntity )

-------------------------------------------------------
function RigidBodyLight:OnLoad(table)  
  self.bRigidBodyActive = table.bRigidBodyActive;
	self.lightSlot = table.lightSlot;
	self.origGlowValue = table.origGlowValue;
	self.materialIsCloned = table.materialIsCloned; 
	self.lightOn = table.lightOn;
	self.destroyed = table.destroyed;
	
end

-------------------------------------------------------
function RigidBodyLight:OnSave(table)  
	table.bRigidBodyActive = self.bRigidBodyActive
	table.lightSlot = self.lightSlot;
	table.origGlowValue = self.origGlowValue;
	table.materialIsCloned = self.materialIsCloned; 
	table.lightOn = self.lightOn;
	table.destroyed = self.destroyed;
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight:OnSpawn()
	if (self.Properties.Physics.bRigidBodyActive == 1) then
		self.bRigidBodyActive = 1;
	end
	self:SetFromProperties();	
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight:SetFromProperties()
	local Properties = self.Properties;
  self.destroyed = false;
	
	if (Properties.object_Model == "") then
		do return end;
	end
	
	self:LoadObject(0,Properties.object_Model);
	self:CharacterUpdateOnRender(0,1); -- If it is a character force it to update on render.
		
	-- Enabling drawing of the slot.
	self:DrawSlot(0,1);
	
	if (Properties.Physics.bPhysicalize == 1) then
		self:PhysicalizeThis();
	end
	
	-- Mark AI hideable flag.
	if (self.Properties.bAutoGenAIHidePts == 1) then
		self:SetFlags(ENTITY_FLAG_AI_HIDEABLE, 0); -- set
	else
		self:SetFlags(ENTITY_FLAG_AI_HIDEABLE, 2); -- remove
	end
	
    -- this is somewhat of a hack: the "or self.lightOn" is there to cover the case when the designer is currently modifying the glow value in the editor. it is irrelevant in pure game
	if (not self.origGlowValue or self.lightOn) then
    self.origGlowValue = self:GetMaterialFloat(0, self.PropertiesInstance.LightProperties_Base.Options.nGlowSubmatId, "glow" );
  end
	
  self.lightOn = self.PropertiesInstance.bTurnedOn==1;
  self:ShowCorrectLight();
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight:PhysicalizeThis()
	-- Init physics.
	local physics = self.Properties.Physics;
	if (CryAction.IsImmersivenessEnabled() == 0) then
		physics = Physics_DX9MP_Simple;
	end
	EntityCommon.PhysicalizeRigid( self,0,physics,self.bRigidBodyActive );
end

------------------------------------------------------------------------------------------------------
-- OnPropertyChange called only by the editor.
------------------------------------------------------------------------------------------------------
function RigidBodyLight:OnPropertyChange()
  if (self.lightOn) then
    self.origGlowValue = self:GetMaterialFloat(0, self.PropertiesInstance.LightProperties_Base.Options.nGlowSubmatId, "glow" );
  end

	self:SetFromProperties();
end

------------------------------------------------------------------------------------------------------
-- OnReset called only by the editor.
------------------------------------------------------------------------------------------------------
function RigidBodyLight:OnReset()
	self:ResetOnUsed();
	self.lightOn = self.PropertiesInstance.bTurnedOn==1;
	self.destroyed = false;
	self.materialIsCloned = false;
  self:ShowCorrectLight();
	
	local PhysProps = self.Properties.Physics;
	if (PhysProps.bPhysicalize == 1) then
		if (self.bRigidBodyActive ~= PhysProps.bRigidBodyActive) then
			self.bRigidBodyActive = PhysProps.bRigidBodyActive;
			self:PhysicalizeThis();
		end
		if (PhysProps.bRigidBody == 1) then
			self:AwakePhysics(1-PhysProps.bResting);
			self.bRigidBodyActive = PhysProps.bRigidBodyActive;
		end		
	end
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight:GetFrozenSlot()
	if (self.frozenModelSlot) then
		return self.frozenModelSlot;
	end
	return -1;
end



------------------------------------------------------------------------------------------------------
function RigidBodyLight:Event_Hide()
	self:Hide(1);
	self:ActivateOutput( "Hidden", true );
	--self:DrawObject(0,0);
	--self:DestroyPhysics();
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight:Event_UnHide()
	self:Hide(0);
	self:ActivateOutput( "UnHidden", true );
	--self:DrawObject(0,1);
	--self:SetPhysicsProperties( 1,self.bRigidBodyActive );
end


function RigidBodyLight:Event_Enable()
  if (not self.destroyed) then
    self.lightOn = true;
    self:ShowCorrectLight();
	  self:ActivateOutput( "Enabled", true );
	end
end

function RigidBodyLight:Event_Disable()
  if (not self.destroyed) then
    self.lightOn = false;
    self:ShowCorrectLight();
	  self:ActivateOutput( "Disabled", true );
	end
end


------------------------------------------------------------------------------------------------------
function RigidBodyLight:ShowLightOn()
  -- light source --
	if (self.lightSlot ~= (-1)) then
		self:FreeSlot(self.lightSlot);
		self.lightSlot = -1;
	end
	if (self.PropertiesInstance.LightProperties_Base.bUseThisLight ~= 0) then
		self:UseLight(1);
	end

  -- glow effect --
  local glowVal = self:GetMaterialFloat(0, self.PropertiesInstance.LightProperties_Base.Options.nGlowSubmatId, "glow" );
  if (glowVal~=self.origGlowValue and self.origGlowValue and self.materialIsCloned) then
    self:SetMaterialFloat(0, self.PropertiesInstance.LightProperties_Base.Options.nGlowSubmatId, "glow", self.origGlowValue );
  end
end


------------------------------------------------------------------------------------------------------
function RigidBodyLight:ShowLightOff()

  -- light source --
	if (self.lightSlot ~= (-1)) then
		self:FreeSlot(self.lightSlot);
		self.lightSlot = -1;
	end
	if (self.PropertiesInstance.LightProperties_Destroyed.bUseThisLight ~= 0) then
		self:UseLight(0);
	end


  -- glow effect --
  local currentGlow = self:GetMaterialFloat(0, self.PropertiesInstance.LightProperties_Base.Options.nGlowSubmatId, "glow" );
  
  if (currentGlow>0) then  
    if (not self.materialIsCloned) then
      self:CloneMaterial(0);
      self.materialIsCloned = true;
    end
  
    self:SetMaterialFloat(0, self.PropertiesInstance.LightProperties_Base.Options.nGlowSubmatId, "glow", 0 );
  end
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight.Client:OnPhysicsBreak( vPos,nPartId,nOtherPartId )
	self:ActivateOutput("Break",nPartId+1 );
	self.destroyed = true;
  self:ShowCorrectLight();
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight.Client:OnCollision(hit)
end

------------------------------------------------------------------------------------------------------
function RigidBodyLight:OnDamage( hit )
	if( hit.ipart and hit.ipart>=0 ) then
		self:AddImpulse( hit.ipart, hit.pos, hit.dir, hit.impact_force_mul );
	end
end

----------------------------------------------------------------------------------------------------
function RigidBodyLight:ShowCorrectLight()
  if (self.lightOn and not self.destroyed) then
    self:ShowLightOn();
  else
    self:ShowLightOff();
  end
end



------------------------------------------------------------------------------------------------------
-- Input events
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------
function RigidBodyLight:UseLight( lightIdx )
	local props;
	if( lightIdx == 0) then 
	 props = self.PropertiesInstance.LightProperties_Destroyed;
	else
	 props = self.PropertiesInstance.LightProperties_Base;
	end
	local Style = props.Style;
	local Projector = props.Projector;
	local Color = props.Color;
	local Options = props.Options;

	local diffuse_mul = Color.fDiffuseMultiplier;
	local specular_mul = Color.fSpecularMultiplier;
	
	local lt = self._LightTable;
	lt.style = Style.nLightStyle;
	lt.corona_scale = Style.fCoronaScale;
	lt.corona_dist_size_factor = Style.fCoronaDistSizeFactor;
	lt.corona_dist_intensity_factor = Style.fCoronaDistIntensityFactor;
	lt.radius = props.Radius;
	lt.diffuse_color = { x=Color.clrDiffuse.x*diffuse_mul, y=Color.clrDiffuse.y*diffuse_mul, z=Color.clrDiffuse.z*diffuse_mul };
	if (diffuse_mul ~= 0) then
		lt.specular_multiplier = specular_mul / diffuse_mul;
	else
		lt.specular_multiplier = 1;
	end
	
	lt.hdrdyn = Color.fHDRDynamic;
	lt.projector_texture = Projector.texture_Texture;
	lt.proj_fov = Projector.fProjectorFov;
	lt.proj_nearplane = Projector.fProjectorNearPlane;
	lt.cubemap = Projector.bProjectInAllDirs;
	lt.this_area_only = Options.bAffectsThisAreaOnly;
	lt.realtime = Options.bUsedInRealTime;
	lt.heatsource = 0;
	lt.fake = Options.bFakeLight;
	lt.deferred_light = Options.bDeferredLight;
	lt.fill_light = props.Test.bFillLight;		
	lt.negative_light = props.Test.bNegativeLight;
	lt.indoor_only = 0;
	lt.has_cbuffer = 0;
	lt.cast_shadow = Options.bCastShadow;
		
	lt.lightmap_linear_attenuation = 1;
	lt.is_rectangle_light = 0;
	lt.is_sphere_light = 0;
	lt.area_sample_number = 1;
	
	lt.RAE_AmbientColor = { x = 0, y = 0, z = 0 };
	lt.RAE_MaxShadow = 1;
	lt.RAE_DistMul = 1;
	lt.RAE_DivShadow = 1;
	lt.RAE_ShadowHeight = 1;
	lt.RAE_FallOff = 2;
	lt.RAE_VisareaNumber = 0;

  lt.viewDistRatio = Options.nViewDistRatio;
	self.lightSlot = self:LoadLight( -1 ,lt );
  local angles = g_Vectors.temp_v1;
  angles.x = 0;
  local xyVectorLen = math.sqrt( props.vDirection.x*props.vDirection.x + props.vDirection.y*props.vDirection.y );
  angles.y = math.atan2( -props.vDirection.z, xyVectorLen );
  angles.z = math.atan2( props.vDirection.y, props.vDirection.x );
	self:SetSlotAngles(self.lightSlot, angles );
	self:SetSlotPos(self.lightSlot, props.vOffset );
	
	if ((props.Options.bCastShadows ~= 0) and (props.Options.bIgnoreGeomCaster ~= 0)) then
		self:SetSelfAsLightCasterException( self.lightSlot );
	end
end



------------------------------------------------------------------------------------------------------
-- Defaul state.
------------------------------------------------------------------------------------------------------
RigidBodyLight.Default = 
{
  OnBeginState = function(self)
    if (self:IsARigidBody()==1) then
      if (self.bRigidBodyActive~=self.Properties.Physics.bRigidBodyActive) then
        self:SetPhysicsProperties( 0,self.Properties.Physics.bRigidBodyActive );
      else
			  self:AwakePhysics(1-self.Properties.Physics.bResting);
		  end  
		end
	end,
	OnDamage = RigidBodyLight.OnDamage,
	OnCollision = RigidBodyLight.OnCollision,
	OnPhysicsBreak = RigidBodyLight.OnPhysicsBreak,
}

------------------------------------------------------------------------------------------------------
-- Activated state.
------------------------------------------------------------------------------------------------------
RigidBodyLight.Activated =
{
	OnBeginState = function(self)
	  if (self:IsARigidBody()==1 and self.bRigidBodyActive==0) then
      self:SetPhysicsProperties( 0,1 );
		  self:AwakePhysics(1);
	  end
	end,
	OnDamage = RigidBodyLight.OnDamage,
	OnCollision = RigidBodyLight.OnCollision,
	OnPhysicsBreak = RigidBodyLight.OnPhysicsBreak,
}

RigidBodyLight.FlowEvents =
{
	Inputs =
	{
		Disable = { RigidBodyLight.Event_Disable, "bool" },
		Enable = { RigidBodyLight.Event_Enable, "bool" },
		Hide = { RigidBodyLight.Event_Hide, "bool" },
		UnHide = { RigidBodyLight.Event_UnHide, "bool" },
		DisableUsable = { RigidBodyLight.Event_DisableUsable, "bool" },
		EnableUsable = { RigidBodyLight.Event_EnableUsable, "bool" },
		Use = { RigidBodyLight.Event_Use, "bool" },
	},
	Outputs =
	{
	  Disabled = "bool",
	  Enabled = "bool",
		Hidden = "bool",
		UnHidden = "bool",
		Used = "bool",
		DisableUsable = "bool",
		EnableUsable = "bool",
		Break = "bool",
		Used = "bool",
	},
}


MakeUsable(RigidBodyLight);

function RigidBodyLight:OnUsed(user, idx)
	BroadcastEvent(self, "Used")
	if (not self.destroyed) then
  	if (self.lightOn) then
      self.lightOn = false;
  	  BroadcastEvent( self, "Disabled" );
	  else
      self.lightOn = true;
  	  BroadcastEvent( self, "Enabled" );
	  end
    self:ShowCorrectLight();
	end
end
