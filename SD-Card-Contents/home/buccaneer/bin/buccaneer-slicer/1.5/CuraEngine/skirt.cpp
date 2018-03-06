/** Copyright (C) 2013 David Braam - Released under terms of the AGPLv3 License */
#include "skirt.h"
#include "support.h"
#include <math.h>

#define PI 3.14159265358979

void generateSkirt(SliceDataStorage& storage, int distance, int extrusionWidth, int count, int minLength)
{
	Polygons skirtPolygons2[1000];

	// Create added smart parts!
        SliceLayer* layer = &storage.volumes[0].layers[0];
        for(unsigned int layer_part_no=0; layer_part_no<layer->parts.size(); layer_part_no++)
        {
		AABB box=layer->parts[layer_part_no].boundaryBox;
		int grid_max=2000000,grid_min=1200;
		int xcentre=(box.min.X+box.max.X)/2,ycentre=(box.min.Y+box.max.Y)/2;

		Polygons central_hole;
		ClipperLib::Polygon poly1;
		Point pp1[8];
		pp1[0].X=-10000+xcentre; pp1[0].Y=10000+ycentre;
		pp1[1].X=-14142+xcentre; pp1[1].Y=0+ycentre;
		pp1[2].X=-10000+xcentre; pp1[2].Y=-10000+ycentre;
		pp1[3].X=0+xcentre;     pp1[3].Y=-14142+ycentre;
		pp1[4].X=10000+xcentre;  pp1[4].Y=-10000+ycentre;
		pp1[5].X=14142+xcentre;  pp1[5].Y=0+ycentre;
		pp1[6].X=10000+xcentre;  pp1[6].Y=10000+ycentre;
		pp1[7].X=0+xcentre;     pp1[7].Y=14142+ycentre;
		for(unsigned int i=0; i<8; i++)
			poly1.push_back(pp1[i]);
		central_hole.add(poly1);

		Point polygonPoint[4];
		polygonPoint[0].X=0;		polygonPoint[0].Y=0;
		polygonPoint[1].X=0+grid_min;	polygonPoint[1].Y=0;
		polygonPoint[2].X=0+grid_min;	polygonPoint[2].Y=0+grid_max;
		polygonPoint[3].X=0;		polygonPoint[3].Y=0+grid_max;

		// prepare anti-warping part...
		double angle=0;
		for(int i=0;i<8;i++)
		{
			ClipperLib::Polygon pp;
			Point polygonPoint2[4];
			float m[4];
			m[0]=cos(angle);
			m[1]=-sin(angle);
			m[2]=sin(angle);
			m[3]=cos(angle);
			angle+=PI/(8/2);
			// apply rotation
			for(unsigned int j=0;j<4;j++)
			{
				polygonPoint2[j].X=(long long int)((double)polygonPoint[j].X*m[0]+(float)polygonPoint[j].Y*m[1])+xcentre;
				polygonPoint2[j].Y=(long long int)((double)polygonPoint[j].X*m[2]+(float)polygonPoint[j].Y*m[3])+ycentre;
				pp.push_back(polygonPoint2[j]);
			}
		
			skirtPolygons2[layer_part_no].add(pp);
			skirtPolygons2[layer_part_no] = skirtPolygons2[layer_part_no].unionPolygons(skirtPolygons2[layer_part_no]);
			skirtPolygons2[layer_part_no] = (skirtPolygons2[layer_part_no].difference(central_hole)).difference(layer->parts[layer_part_no].outline.offset(distance + extrusionWidth / 2));
		}
        }

	for(int skirtNr=0; skirtNr<count;skirtNr++)
	{
		Polygons skirtPolygons;

		SupportPolyGenerator supportGenerator(storage.support, 0);
		skirtPolygons = skirtPolygons.unionPolygons(supportGenerator.polygons.offset(distance + extrusionWidth * skirtNr + extrusionWidth / 2));


		Polygons skirtPolygons4[layer->parts.size()];
		for(unsigned int volumeIdx = 0; volumeIdx < storage.volumes.size(); volumeIdx++)
		{
		    if (storage.volumes[volumeIdx].layers.size() < 1) continue;
		    SliceLayer* layer = &storage.volumes[volumeIdx].layers[0];
		    for(unsigned int i=0; i<layer->parts.size(); i++)
		    {
			skirtPolygons4[i] = skirtPolygons4[i].unionPolygons(layer->parts[i].outline.offset(distance + extrusionWidth * skirtNr + extrusionWidth / 2));
		    }
		}

		for(unsigned int i=0; i<layer->parts.size(); i++)
		{
			skirtPolygons = skirtPolygons.unionPolygons(skirtPolygons4[i].difference(skirtPolygons2[i]));
		}

		storage.skirt.add(skirtPolygons);
		storage.skirt = storage.skirt.intersection(skirtPolygons);

		int lenght = storage.skirt.polygonLength();
		if (skirtNr + 1 >= count && lenght > 0 && lenght < minLength)
		    count++;
	}
}

