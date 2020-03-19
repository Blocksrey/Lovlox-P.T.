local acoustics = {}

acoustics.genericreverb = {
	type           = "reverb";
	gain           = 1;
	highgain       = 1;
	density        = 1;
	diffusion      = 1;
	decaytime      = 3;
	decayhighratio = 0;
	earlygain      = 1;
	earlydelay     = 0;
	lategain       = 1;
	latedelay      = 0;
	roomrolloff    = 0;
	airabsorption  = 1;
	highlimit      = false;
}

acoustics.forestreverb = {
	type           = "reverb";
	gain           = 1;
	highgain       = 1;
	density        = 1;
	diffusion      = 1;
	decaytime      = 3;
	decayhighratio = 0;
	earlygain      = 1;
	earlydelay     = 2;
	lategain       = 1;
	latedelay      = 2;
	roomrolloff    = 0;
	airabsorption  = 1;
	highlimit      = false;
}

return acoustics