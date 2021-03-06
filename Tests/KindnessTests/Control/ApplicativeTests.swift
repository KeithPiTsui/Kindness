// Copyright © 2018 the Kindness project contributors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftCheck

import Kindness

func applicativeIdentityLaw<A: Arbitrary, F: Applicative, E: Equatable>(
    makeFunctor: @escaping (A) -> F,
    makeEquatable: @escaping (F) -> E
) -> Property {
    return forAll { (a: A) -> Bool in
        let f = makeFunctor(a)

        let lhs = makeEquatable(pure(id) <*> f)
        let rhs = makeEquatable(f)
        return lhs == rhs
    }
}

func applicativeCompositionLaw<A: Arbitrary, F: Applicative, E: Equatable, B: Arbitrary, FAB: Applicative>(
    makeFunctor: @escaping (A) -> F,
    makeEquatable: @escaping (F) -> E,
    makeFAB: @escaping (B) -> FAB
) -> Property where
    F.K1Arg: Arbitrary & CoArbitrary & Hashable,
    F.K1Tag == FAB.K1Tag,
    FAB.K1Arg == ArrowOf<F.K1Arg, F.K1Arg> {
        return forAll { (fArrows: B, gArrows: B, a: A) -> Bool in
            let h = makeFunctor(a)

            let f = { $0.getArrow } <^> makeFAB(fArrows)
            let g = { $0.getArrow } <^> makeFAB(gArrows)

            let lhs: E = makeEquatable(pure(curry(•)) <*> f <*> g <*> h)
            let rhs: E = makeEquatable(f <*> (g <*> h))

            return lhs == rhs
        }
}

func applicativeHomomorphismLaw<F: Applicative, E: Equatable>(
    makeEquatable: @escaping (F) -> E
) -> Property where F.K1Arg: Arbitrary & CoArbitrary & Hashable {
    return forAll { (fArrow: ArrowOf<F.K1Arg, F.K1Arg>, x: F.K1Arg) -> Bool in
        let f = fArrow.getArrow

        let lhs: E = makeEquatable(pure(f) <*> (pure(x) as F))
        let rhs: E = makeEquatable(pure(f(x)))

        return lhs == rhs
    }
}

func applicativeInterchangeLaw<F: Applicative, E: Equatable, B: Arbitrary, FAB: Applicative>(
    makeEquatable: @escaping (F) -> E,
    makeFAB: @escaping (B) -> FAB
) -> Property where
    F.K1Arg: Arbitrary & CoArbitrary & Hashable,
    F.K1Tag == FAB.K1Tag,
    FAB.K1Arg == ArrowOf<F.K1Arg, F.K1Arg> {
        return forAll { (fArrows: B, x: F.K1Arg) -> Bool in
            let f = { $0.getArrow } <^> makeFAB(fArrows)

            let lhs: E = makeEquatable(f <*> pure(x))
            let rhs: E = makeEquatable(pure(curry(|>)(x)) <*> f)

            return lhs == rhs
        }
}

func checkApplicativeLaws<F: Applicative & Arbitrary & Equatable, FAB: Applicative & Arbitrary>(
    for: F.Type, fabType: FAB.Type
) where F.K1Arg: Arbitrary & CoArbitrary & Hashable, F.K1Tag == FAB.K1Tag, FAB.K1Arg == ArrowOf<F.K1Arg, F.K1Arg> {
    let idF: (F) -> F = id
    let idFAB: (FAB) -> (FAB) = id

    property("Applicative - Identity: pure(id) <*> v == v")
        <- applicativeIdentityLaw(makeFunctor: idF, makeEquatable: idF)

    property("Applicative - Composition: pure(<<<) <*> f <*> g <*> h == f <*> (g <*> h)")
        <- applicativeCompositionLaw(makeFunctor: idF, makeEquatable: idF, makeFAB: idFAB)

    property("Applicative - Homomorphism: pure(f) <*> pure(x) == pure(f(x))")
        <- applicativeHomomorphismLaw(makeEquatable: idF)

    property("Applicative - Interchange: u <*> pure(y) == pure ((|>) y) <*> u")
        <- applicativeInterchangeLaw(makeEquatable: idF, makeFAB: idFAB)
}

func applicativeLaws<A: Arbitrary, F: Applicative, E: Equatable, B: Arbitrary, FAB: Applicative>(
    makeFunctor: @escaping (A) -> F,
    makeEquatable: @escaping (F) -> E,
    makeFAB: @escaping (B) -> FAB
) -> Property where
    F.K1Arg: Arbitrary & CoArbitrary & Hashable,
    F.K1Tag == FAB.K1Tag,
    FAB.K1Arg == ArrowOf<F.K1Arg, F.K1Arg> {
        return conjoin(
            applicativeIdentityLaw(makeFunctor: makeFunctor, makeEquatable: makeEquatable),
            applicativeCompositionLaw(makeFunctor: makeFunctor, makeEquatable: makeEquatable, makeFAB: makeFAB),
            applicativeHomomorphismLaw(makeEquatable: makeEquatable),
            applicativeInterchangeLaw(makeEquatable: makeEquatable, makeFAB: makeFAB)
        )
}
