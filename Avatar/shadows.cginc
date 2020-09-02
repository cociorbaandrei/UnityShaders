#pragma once
fixed4 frag( PIO process, uint isFrontFace : SV_IsFrontFace ) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(process)
}