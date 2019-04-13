#ifndef HERO_CORE_FORWARD_INCLUDED
#define HERO_CORE_FORWARD_INCLUDED

#include "HeroCore.cginc"

VertexOutputForwardBase vertBase(VertexInput v) { return Internal_VertForwardBase(v); }
half4 fragBase(VertexOutputForwardBase i) : SV_Target{ return Internal_FragForwardBase(i); }

//VertexOutputForwardAdd vertAdd(VertexInput v) { return Internal_VertForwardAdd(v); }
//half4 fragAdd(VertexOutputForwardAdd i) : SV_Target{ return fragForwardAddInternal(i); }

#endif // HERO_CORE_FORWARD_INCLUDED