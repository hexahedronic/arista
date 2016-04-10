local entity = FindMetaTable("Entity")

function entity:seal(unseal)
	hook.Run("EntitySealed", self, unseal)
	self:networkAristaVar("sealed", not unseal)
end

function entity:lock(delay, override)
	if not arista.entity.isOwnable(self) then return false end
	if self:isJammed() and not override then return false end

	if delay and delay > 0 then
		timer.Simple(delay, function()
			if not IsValid(self) then return end

			self:Lock(0, override)
		end)

		return
	end

	if self._isDoor or self._isVehicle then
		self:Fire("lock")
	end

	self:networkAristaVar("locked", true)
end

function entity:unLock(delay, override)
	if not arista.entity.isOwnable(self) then return false end
	if self:isJammed() and not override then return false end

	if delay and delay > 0 then
		timer.Simple(delay, function()
			if not IsValid(self) then return end

			self:unLock(0, override)
		end)

		return
	end

	if self._isDoor or self._isVehicle then
		self:Fire("unlock")
	end

	self:networkAristaVar("locked", false)
end
