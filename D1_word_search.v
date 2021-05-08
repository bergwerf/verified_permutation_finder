(* Minkwitz' brute-force short-word generator search. *)

From CGT Require Import A1_setup B1_fmap B2_perm B3_word.
From CGT Require Import C1_Schreier_vector C3_subgroup_chain.

Module Minkwitz.

Section Algorithm.

(***
:: Search table ::

The table is a list of triples (k, c, i ↦ π × w) representing each subgroup
generated by the Schreier-Sims algorithm. The only information needed from this
algorithm is the length of the orbits, such that the search can be terminated
when all generators are found. The triples carry the following information:
- The subgroup stabilizer point: k.
- The size of the orbit of k minus the orbit permutations already found: c.
- A map from an orbit value i to a permutation π and a word w such that:
  π maps k to i, π is generated by w, and w is fully reduced.
*)
Definition table := list (positive × nat × fmap (perm × word)).

(* Determine if the table is filled out. *)
Fixpoint finished (T : table) :=
  match T with
  | [] => true
  | (_, O, _) :: T' => finished T'
  | _ => false
  end.

(* Try to add the given permutation to the table. *)
Fixpoint push (T : table) (π : perm) (w : word) : table :=
  match T with
  | [] => []
  | (k, c, row) :: T' =>
    let j := π⋅k in
    match lookup row j with
    | None => (k, pred c, insert row j (π, w)) :: T'
    | Some (π', w') =>
      if (length w <? length w')%nat
      then (k, c, insert row j (π, w)) :: T'
      else (k, c, row) :: push T' (inv π' ∘ π) (reduce [] (inv_word w' ++ w))
    end
  end.

(* Determine the next word, and add it to the table. *)
Definition step gen (state : word × table) : word × table × bool :=
  match state with
  | (w, T) =>
    let w' := next_word (pred (length gen)) w in
    let T' := push T (generate gen w') w' in
    (w', T', finished T')
  end.

(***
:: Search space ::

I believe that the search is certain to converge after checking all words of
length at most n! (track the maximum word length along the subgroup chain). Of
course in practice the search should converge _much_ faster. But in Coq all
functions must terminate, so I would like to give a theoretical upper bound.
Since every step checks the next word, I think this upper bound should be c^n!,
where c is twice the size of the generating set.

To repeat an operation such a large number of times I added iteration functions
with an ealy termination boolean. I have not yet found a simple way to repeat
c^n! times. The current implementation only repeats c*n! times.
*)

(* Repeat a task n times. *)
Fixpoint iter {X} n (f : X -> X × bool) (x : X) : X × bool :=
  match n with
  | O => (x, false)
  | S m =>
    match f x with
    | (y, b) => if b then (y, true) else iter m f y
    end
  end.

(* Repeat a task n! times. *)
Fixpoint iter_fact {X} n (f : X -> X × bool) : X -> X × bool :=
  match n with
  | O => f
  | S m => iter (S m) (iter_fact m f)
  end.

(* Initialize the table and execute enough steps to fill it out. *)
Definition simplify (gen : list perm) (C : SGChain.chain) : table :=
  let c := Nat.double (length gen) in
  let T := map (λ sg, (snd (fst sg), size (snd sg), Leaf)) C in
  let state := iter_fact (length T) (iter c (step gen)) ([], T) in
  snd (fst state).

End Algorithm.

End Minkwitz.
