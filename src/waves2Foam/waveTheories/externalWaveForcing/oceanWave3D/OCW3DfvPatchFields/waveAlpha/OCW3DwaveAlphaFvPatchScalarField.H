/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | Copyright held by original author
     \\/     M anipulation  |
-------------------------------------------------------------------------------
License
    This file is part of OpenFOAM.

    OpenFOAM is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM; if not, write to the Free Software Foundation,
    Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

Class
    Foam::OCW3DwaveAlphaFvPatchScalarField

Description
    Boundary condition for the VOF-fraction in a multiphase solver. To be used
    for wave boundary conditions. For more details see:

    @article { jacobsenFuhrmanFredsoe2011,
        Author = {Jacobsen, N G and Fuhrman, D R and Freds\o{}e, J},
        title = {{A Wave Generation Toolbox for the Open-Source CFD Library: OpenFoam\textregistered{}}},
        Journal = {{Int. J. for Numer. Meth. Fluids}},
        Year = {2012},
        Volume = {70},
        Number = {9},
        Pages = {1073-1088},
        DOI = {{10.1002/fld.2726}},
    }

    The boundary condition is derived from mixedFvPatchField and it is generic
    in the sense, that it loads the abstract class waveTheory.

SourceFiles
    OCW3DwaveAlphaFvPatchScalarField.C

Author
    Niels Gjøl Jacobsen, Technical University of Denmark.  All rights reserved.


\*---------------------------------------------------------------------------*/

#ifndef OCW3DwaveAlphaFvPatchScalarField_H
#define OCW3DwaveAlphaFvPatchScalarField_H

#include "mixedFvPatchField.H"
#include "convexPolyhedral.H"
#include "waveTheory.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
                 Class OCW3DwaveAlphaFvPatchScalarField Declaration
\*---------------------------------------------------------------------------*/

class OCW3DwaveAlphaFvPatchScalarField
:
    public mixedFvPatchField<scalar>,
    public convexPolyhedral
{

private:

    //- Private member functions
        autoPtr<waveTheories::waveTheory> waveProps_;

    // Private member functions

    //- Returns a scalarField of the signed distance to an arbitrary surface
        virtual void signedPointToSurfaceDistance
        (
            const pointField&,
            scalarField&
        );


    //- Returns a scalar of the signed distance to an arbitrary surface
        virtual scalar signedPointToSurfaceDistance
        (
            const point&
        ) const;

public:

    //- Runtime type information
    TypeName("OCW3DwaveAlpha");


    // Constructors

        //- Construct from patch and internal field
        OCW3DwaveAlphaFvPatchScalarField
        (
            const fvPatch&,
            const DimensionedField<scalar, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        OCW3DwaveAlphaFvPatchScalarField
        (
            const fvPatch&,
            const DimensionedField<scalar, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping given surfaceWaveVelocityFvPatchVectorField
        //  onto a new patch
        OCW3DwaveAlphaFvPatchScalarField
        (
            const OCW3DwaveAlphaFvPatchScalarField&,
            const fvPatch&,
            const DimensionedField<scalar, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct and return a clone
        virtual tmp<fvPatchField<scalar> > clone() const
        {
            return tmp<fvPatchField<scalar> >
            (
                new OCW3DwaveAlphaFvPatchScalarField(*this)
            );
        }

        //- Construct as copy setting internal field reference
        OCW3DwaveAlphaFvPatchScalarField
        (
            const OCW3DwaveAlphaFvPatchScalarField&,
            const DimensionedField<scalar, volMesh>&
        );

        //- Construct and return a clone setting internal field reference
        virtual tmp<fvPatchField<scalar> > clone
        (
            const DimensionedField<scalar,
            volMesh>& iF
        ) const
        {
            return tmp<fvPatchField<scalar> >
            (
                new OCW3DwaveAlphaFvPatchScalarField(*this, iF)
            );
        }


    // Member functions

        //- Update the coefficients associated with the patch field
        virtual void updateCoeffs();

        //- Evaluate the patch field
        virtual void evaluate();

        //- Write
        virtual void write(Ostream&) const;
};


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

//#ifdef NoRepository
//#   include "surfaceWaveVelocityFvPatchVectorField.C"
//#endif

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
