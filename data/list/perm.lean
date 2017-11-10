/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura, Jeremy Avigad, Mario Carneiro

List permutations.
-/
import data.list.basic

namespace list
universe variables uu vv
variables {α : Type uu} {β : Type vv}

inductive perm : list α → list α → Prop
| nil   : perm [] []
| skip  : Π (x : α) {l₁ l₂ : list α}, perm l₁ l₂ → perm (x::l₁) (x::l₂)
| swap  : Π (x y : α) (l : list α), perm (y::x::l) (x::y::l)
| trans : Π {l₁ l₂ l₃ : list α}, perm l₁ l₂ → perm l₂ l₃ → perm l₁ l₃
open perm

infix ~ := perm

@[refl] protected theorem perm.refl : ∀ (l : list α), l ~ l
| []      := perm.nil
| (x::xs) := skip x (perm.refl xs)

@[symm] protected theorem perm.symm {l₁ l₂ : list α} (p : l₁ ~ l₂) : l₂ ~ l₁ :=
perm.rec_on p
  perm.nil
  (λ x l₁ l₂ p₁ r₁, skip x r₁)
  (λ x y l, swap y x l)
  (λ l₁ l₂ l₃ p₁ p₂ r₁ r₂, trans r₂ r₁)

attribute [trans] perm.trans

theorem perm.eqv (α : Type) : equivalence (@perm α) :=
mk_equivalence (@perm α) (@perm.refl α) (@perm.symm α) (@perm.trans α)

attribute [instance]
protected def is_setoid (α : Type) : setoid (list α) :=
setoid.mk (@perm α) (perm.eqv α)

theorem perm_subset {l₁ l₂ : list α} (p : l₁ ~ l₂) : l₁ ⊆ l₂ :=
λ a, perm.rec_on p
  (λ h, h)
  (λ x l₁ l₂ p₁ r₁ i, or.elim i
    (λ ax, by simp [ax])
    (λ al₁, or.inr (r₁ al₁)))
  (λ x y l ayxl, or.elim ayxl
    (λ ay, by simp [ay])
    (λ axl, or.elim axl
      (λ ax, by simp [ax])
      (λ al, or.inr (or.inr al))))
  (λ l₁ l₂ l₃ p₁ p₂ r₁ r₂ ainl₁, r₂ (r₁ ainl₁))

theorem mem_of_perm {a : α} {l₁ l₂ : list α} (h : l₁ ~ l₂) : a ∈ l₁ ↔ a ∈ l₂ :=
iff.intro (λ m, perm_subset h m) (λ m, perm_subset h.symm m)

theorem perm_app_left {l₁ l₂ : list α} (t₁ : list α) (p : l₁ ~ l₂) : l₁++t₁ ~ l₂++t₁ :=
perm.rec_on p
  (perm.refl ([] ++ t₁))
  (λ x l₁ l₂ p₁ r₁, skip x r₁)
  (λ x y l, swap x y _)
  (λ l₁ l₂ l₃ p₁ p₂ r₁ r₂, trans r₁ r₂)

theorem perm_app_right {t₁ t₂ : list α} : ∀ (l : list α), t₁ ~ t₂ → l++t₁ ~ l++t₂
| []      p := p
| (x::xs) p := skip x (perm_app_right xs p)

theorem perm_app {l₁ l₂ t₁ t₂ : list α} (p₁ : l₁ ~ l₂) (p₂ : t₁ ~ t₂) : l₁++t₁ ~ l₂++t₂ :=
trans (perm_app_left t₁ p₁) (perm_app_right l₂ p₂)

theorem perm_app_cons (a : α) {h₁ h₂ t₁ t₂ : list α}
  (p₁ : h₁ ~ h₂) (p₂ : t₁ ~ t₂) : h₁ ++ a::t₁ ~ h₂ ++ a::t₂ :=
perm_app p₁ (skip a p₂)

@[simp] theorem perm_middle {a : α} : ∀ {l₁ l₂ : list α}, l₁++a::l₂ ~ a::(l₁++l₂)
| []      l₂ := perm.refl _
| (b::l₁) l₂ := (skip b (@perm_middle l₁ l₂)).trans (swap a b _)

@[simp] theorem perm_cons_app (a : α) (l : list α) : l ++ [a] ~ a::l :=
by simpa using @perm_middle _ a l []

@[simp] theorem perm_app_comm : ∀ {l₁ l₂ : list α}, (l₁++l₂) ~ (l₂++l₁)
| []     l₂ := by simp
| (a::t) l₂ := (skip a perm_app_comm).trans perm_middle.symm

theorem concat_perm (l : list α) (a : α) : concat l a ~ a :: l :=
by simp

theorem perm_length {l₁ l₂ : list α} (p : l₁ ~ l₂) : length l₁ = length l₂ :=
perm.rec_on p
  rfl
  (λ x l₁ l₂ p r, by simp[r])
  (λ x y l, by simp)
  (λ l₁ l₂ l₃ p₁ p₂ r₁ r₂, eq.trans r₁ r₂)

theorem eq_nil_of_perm_nil {l₁ : list α} (p : [] ~ l₁) : l₁ = [] :=
eq_nil_of_length_eq_zero (perm_length p).symm

theorem not_perm_nil_cons (x : α) (l : list α) : ¬ [] ~ x::l
| p := by injection eq_nil_of_perm_nil p

theorem eq_singleton_of_perm {a b : α} (p : [a] ~ [b]) : a = b :=
by simpa using perm_subset p (by simp)

theorem eq_singleton_of_perm_inv {a : α} {l : list α} (p : [a] ~ l) : l = [a] :=
match l, show 1 = _, from perm_length p, p with
| [a'], rfl, p := by rw [eq_singleton_of_perm p]
end

@[simp] theorem reverse_perm : ∀ (l : list α), reverse l ~ l
| []     := perm.nil
| (a::l) := by rw reverse_cons'; exact
  (perm_cons_app _ _).trans (skip a $ reverse_perm l)

theorem perm_cons_app_cons {l l₁ l₂ : list α} (a : α) (p : l ~ l₁++l₂) : a::l ~ l₁++(a::l₂) :=
trans (skip a p) perm_middle.symm

@[simp] theorem perm_repeat {a : α} {n : ℕ} {l : list α} : repeat a n ~ l ↔ repeat a n = l :=
⟨λ p, (eq_repeat.2 $ by exact
  ⟨by simpa using (perm_length p).symm,
   λ b m, eq_of_mem_repeat $ perm_subset p.symm m⟩).symm,
 λ h, h ▸ perm.refl _⟩

theorem perm_erase [decidable_eq α] {a : α} {l : list α} (h : a ∈ l) : l ~ a :: l.erase a :=
let ⟨l₁, l₂, _, e₁, e₂⟩ := exists_erase_eq h in
e₂.symm ▸ e₁.symm ▸ perm_middle

@[elab_as_eliminator] theorem perm_induction_on
    {P : list α → list α → Prop} {l₁ l₂ : list α} (p : l₁ ~ l₂)
    (h₁ : P [] [])
    (h₂ : ∀ x l₁ l₂, l₁ ~ l₂ → P l₁ l₂ → P (x::l₁) (x::l₂))
    (h₃ : ∀ x y l₁ l₂, l₁ ~ l₂ → P l₁ l₂ → P (y::x::l₁) (x::y::l₂))
    (h₄ : ∀ l₁ l₂ l₃, l₁ ~ l₂ → l₂ ~ l₃ → P l₁ l₂ → P l₂ l₃ → P l₁ l₃) :
  P l₁ l₂ :=
have P_refl : ∀ l, P l l, from
  assume l,
  list.rec_on l h₁ (λ x xs ih, h₂ x xs xs (perm.refl xs) ih),
perm.rec_on p h₁ h₂ (λ x y l, h₃ x y l l (perm.refl l) (P_refl l)) h₄

theorem xswap {l₁ l₂ : list α} (x y : α) (p : l₁ ~ l₂) : x::y::l₁ ~ y::x::l₂ :=
(swap y x l₁).trans $ skip y $ skip x p

@[congr] theorem perm_filter_map (f : α → option β) {l₁ l₂ : list α} (p : l₁ ~ l₂) :
  filter_map f l₁ ~ filter_map f l₂ :=
begin
  induction p with x l₂ l₂' p IH  x y l₂  l₂ m₂ r₂ p₁ p₂ IH₁ IH₂,
  { simp },
  { simp [filter_map], cases f x with a; simp [filter_map, IH, skip] },
  { simp [filter_map], cases f x with a; cases f y with b; simp [filter_map, swap] },
  { exact IH₁.trans IH₂ }
end

@[congr] theorem perm_map (f : α → β) {l₁ l₂ : list α} (p : l₁ ~ l₂) :
  map f l₁ ~ map f l₂ :=
by rw ← filter_map_eq_map; apply perm_filter_map _ p

theorem perm_filter (p : α → Prop) [decidable_pred p]
  {l₁ l₂ : list α} (s : l₁ ~ l₂) : filter p l₁ ~ filter p l₂ :=
by rw ← filter_map_eq_filter; apply perm_filter_map _ s

theorem exists_perm_sublist {l₁ l₂ l₂' : list α}
  (s : l₁ <+ l₂) (p : l₂ ~ l₂') : ∃ l₁' ~ l₁, l₁' <+ l₂' :=
begin
  induction p with x l₂ l₂' p IH  x y l₂  l₂ m₂ r₂ p₁ p₂ IH₁ IH₂ generalizing l₁ s,
  { exact ⟨[], eq_nil_of_sublist_nil s ▸ perm.refl _, nil_sublist _⟩ },
  { cases s with _ _ _ s l₁ _ _ s,
    { exact let ⟨l₁', p', s'⟩ := IH s in ⟨l₁', p', s'.cons _ _ _⟩ },
    { exact let ⟨l₁', p', s'⟩ := IH s in ⟨x::l₁', skip x p', s'.cons2 _ _ _⟩ } },
  { cases s with _ _ _ s l₁ _ _ s; cases s with _ _ _ s l₁ _ _ s,
    { exact ⟨l₁, perm.refl _, (s.cons _ _ _).cons _ _ _⟩ },
    { exact ⟨x::l₁, perm.refl _, (s.cons _ _ _).cons2 _ _ _⟩ },
    { exact ⟨y::l₁, perm.refl _, (s.cons2 _ _ _).cons _ _ _⟩ },
    { exact ⟨x::y::l₁, perm.swap _ _ _, (s.cons2 _ _ _).cons2 _ _ _⟩ } },
  { exact let ⟨m₁, pm, sm⟩ := IH₁ s, ⟨r₁, pr, sr⟩ := IH₂ sm in
          ⟨r₁, pr.trans pm, sr⟩ }
end

section subperm

def subperm (l₁ l₂ : list α) : Prop := ∃ l ~ l₁, l <+ l₂

infix ` <+~ `:50 := subperm

theorem perm.subperm_left {l l₁ l₂ : list α} (p : l₁ ~ l₂) : l <+~ l₁ ↔ l <+~ l₂ :=
suffices ∀ {l₁ l₂ : list α}, l₁ ~ l₂ → l <+~ l₁ → l <+~ l₂,
from ⟨this p, this p.symm⟩,
λ l₁ l₂ p ⟨u, pu, su⟩,
  let ⟨v, pv, sv⟩ := exists_perm_sublist su p in
  ⟨v, pv.trans pu, sv⟩

theorem perm.subperm_right {l₁ l₂ l : list α} (p : l₁ ~ l₂) : l₁ <+~ l ↔ l₂ <+~ l :=
⟨λ ⟨u, pu, su⟩, ⟨u, pu.trans p, su⟩,
 λ ⟨u, pu, su⟩, ⟨u, pu.trans p.symm, su⟩⟩

theorem subperm_of_sublist {l₁ l₂ : list α} (s : l₁ <+ l₂) : l₁ <+~ l₂ :=
⟨l₁, perm.refl _, s⟩

theorem subperm_of_perm {l₁ l₂ : list α} (p : l₁ ~ l₂) : l₁ <+~ l₂ :=
⟨l₂, p.symm, sublist.refl _⟩

theorem subperm.refl (l : list α) : l <+~ l := subperm_of_perm (perm.refl _)

theorem subperm.trans {l₁ l₂ l₃ : list α} : l₁ <+~ l₂ → l₂ <+~ l₃ → l₁ <+~ l₃
| s ⟨l₂', p₂, s₂⟩ :=
  let ⟨l₁', p₁, s₁⟩ := p₂.subperm_left.2 s in ⟨l₁', p₁, s₁.trans s₂⟩

theorem length_le_of_subperm {l₁ l₂ : list α} : l₁ <+~ l₂ → length l₁ ≤ length l₂
| ⟨l, p, s⟩ := perm_length p ▸ length_le_of_sublist s

theorem subperm.perm_of_length_le {l₁ l₂ : list α} : l₁ <+~ l₂ → length l₂ ≤ length l₁ → l₁ ~ l₂
| ⟨l, p, s⟩ h :=
  suffices l = l₂, from this ▸ p.symm,
  eq_of_sublist_of_length_eq s $ le_antisymm (length_le_of_sublist s) $
  perm_length p.symm ▸ h

theorem subperm.antisymm {l₁ l₂ : list α} (h₁ : l₁ <+~ l₂) (h₂ : l₂ <+~ l₁) : l₁ ~ l₂ :=
h₁.perm_of_length_le (length_le_of_subperm h₂)

theorem subset_of_subperm {l₁ l₂ : list α} : l₁ <+~ l₂ → l₁ ⊆ l₂
| ⟨l, p, s⟩ := subset.trans (perm_subset p.symm) (subset_of_sublist s)

end subperm

theorem exists_perm_append_of_sublist : ∀ {l₁ l₂ : list α}, l₁ <+ l₂ → ∃ l, l₂ ~ l₁ ++ l
| ._ ._ sublist.slnil            := ⟨nil, perm.refl _⟩
| ._ ._ (sublist.cons l₁ l₂ a s) :=
  let ⟨l, p⟩ := exists_perm_append_of_sublist s in
  ⟨a::l, (skip a p).trans perm_middle.symm⟩
| ._ ._ (sublist.cons2 l₁ l₂ a s) :=
  let ⟨l, p⟩ := exists_perm_append_of_sublist s in
  ⟨l, skip a p⟩

theorem perm_countp (p : α → Prop) [decidable_pred p]
  {l₁ l₂ : list α} (s : l₁ ~ l₂) : countp p l₁ = countp p l₂ :=
by rw [countp_eq_length_filter, countp_eq_length_filter];
   exact perm_length (perm_filter _ s)

theorem countp_le_of_subperm (p : α → Prop) [decidable_pred p]
  {l₁ l₂ : list α} : l₁ <+~ l₂ → countp p l₁ ≤ countp p l₂
| ⟨l, p', s⟩ := perm_countp p p' ▸ countp_le_of_sublist s

theorem perm_count [decidable_eq α] {l₁ l₂ : list α}
  (p : l₁ ~ l₂) (a) : count a l₁ = count a l₂ :=
perm_countp _ p

theorem count_le_of_subperm [decidable_eq α] {l₁ l₂ : list α}
  (s : l₁ <+~ l₂) (a) : count a l₁ ≤ count a l₂ :=
countp_le_of_subperm _ s

theorem foldl_eq_of_perm {f : β → α → β} {l₁ l₂ : list α} (rcomm : right_commutative f) (p : l₁ ~ l₂) :
  ∀ b, foldl f b l₁ = foldl f b l₂ :=
perm_induction_on p
  (λ b, rfl)
  (λ x t₁ t₂ p r b, r (f b x))
  (λ x y t₁ t₂ p r b, by simp; rw rcomm; exact r (f (f b x) y))
  (λ t₁ t₂ t₃ p₁ p₂ r₁ r₂ b, eq.trans (r₁ b) (r₂ b))

theorem foldr_eq_of_perm {f : α → β → β} {l₁ l₂ : list α} (lcomm : left_commutative f) (p : l₁ ~ l₂) :
  ∀ b, foldr f b l₁ = foldr f b l₂ :=
perm_induction_on p
  (λ b, rfl)
  (λ x t₁ t₂ p r b, by simp; rw [r b])
  (λ x y t₁ t₂ p r b, by simp; rw [lcomm, r b])
  (λ t₁ t₂ t₃ p₁ p₂ r₁ r₂ a, eq.trans (r₁ a) (r₂ a))


section
variables {op : α → α → α} [is_associative α op] [is_commutative α op]
local notation a * b := op a b
local notation l <*> a := foldl op a l

lemma fold_op_eq_of_perm {l₁ l₂ : list α} {a : α} (h : l₁ ~ l₂) : l₁ <*> a = l₂ <*> a :=
foldl_eq_of_perm (right_comm _ (is_commutative.comm _) (is_associative.assoc _)) h _
end

section comm_monoid
open list
variable [comm_monoid α]

@[to_additive list.sum_eq_of_perm]
lemma prod_eq_of_perm {l₁ l₂ : list α} (h : perm l₁ l₂) : prod l₁ = prod l₂ :=
by induction h; simp *

@[to_additive list.sum_reverse]
lemma prod_reverse (l : list α) : prod l.reverse = prod l :=
prod_eq_of_perm $ reverse_perm l

end comm_monoid

theorem perm_inv_core {a : α} {l₁ l₂ r₁ r₂ : list α} : l₁++a::r₁ ~ l₂++a::r₂ → l₁++r₁ ~ l₂++r₂ :=
begin
  generalize e₁ : l₁++a::r₁ = s₁, generalize e₂ : l₂++a::r₂ = s₂,
  intro p, revert l₁ l₂ r₁ r₂ e₁ e₂,
  refine perm_induction_on p _ (λ x t₁ t₂ p IH, _) (λ x y t₁ t₂ p IH, _) (λ t₁ t₂ t₃ p₁ p₂ IH₁ IH₂, _);
    intros l₁ l₂ r₁ r₂ e₁ e₂,
  { apply (not_mem_nil a).elim, rw ← e₁, simp },
  { cases l₁ with y l₁; cases l₂ with z l₂;
      dsimp at e₁ e₂; injections; subst x,
    { substs t₁ t₂,     exact p },
    { substs z t₁ t₂,   exact p.trans perm_middle },
    { substs y t₁ t₂,   exact perm_middle.symm.trans p },
    { substs z t₁ t₂,   exact skip y (IH rfl rfl) } },
  { rcases l₁ with _|⟨y, _|⟨z, l₁⟩⟩; rcases l₂ with _|⟨u, _|⟨v, l₂⟩⟩;
      dsimp at e₁ e₂; injections; substs x y,
    { substs r₁ r₂,     exact skip a p },
    { substs r₁ r₂,     exact skip u p },
    { substs r₁ v t₂,   exact skip u (p.trans perm_middle) },
    { substs r₁ r₂,     exact skip y p },
    { substs r₁ r₂ y u, exact skip a p },
    { substs r₁ u v t₂, exact (skip y $ p.trans perm_middle).trans (swap _ _ _) },
    { substs r₂ z t₁,   exact skip y (perm_middle.symm.trans p) },
    { substs r₂ y z t₁, exact (swap _ _ _).trans (skip u $ perm_middle.symm.trans p) },
    { substs u v t₁ t₂, exact (swap _ _ _).trans (skip z $ skip y $ IH rfl rfl) } },
  { substs t₁ t₃,
    have : a ∈ t₂ := perm_subset p₁ (by simp),
    rcases mem_split this with ⟨l₂, r₂, e₂⟩,
    subst t₂, exact (IH₁ rfl rfl).trans (IH₂ rfl rfl) }
end

theorem perm_cons_inv {a : α} {l₁ l₂ : list α} : a::l₁ ~ a::l₂ → l₁ ~ l₂ :=
@perm_inv_core _ _ [] [] _ _

theorem perm_cons (a : α) {l₁ l₂ : list α} : a::l₁ ~ a::l₂ ↔ l₁ ~ l₂ :=
⟨perm_cons_inv, skip a⟩

theorem perm_app_left_iff {l₁ l₂ : list α} : ∀ l, l++l₁ ~ l++l₂ ↔ l₁ ~ l₂
| []     := iff.rfl
| (a::l) := (perm_cons a).trans (perm_app_left_iff l)

theorem perm_app_right_iff {l₁ l₂ : list α} (l) : l₁++l ~ l₂++l ↔ l₁ ~ l₂ :=
⟨λ p, (perm_app_left_iff _).1 $ trans perm_app_comm $ trans p perm_app_comm,
 perm_app_left _⟩

theorem subperm_cons (a : α) {l₁ l₂ : list α} : a::l₁ <+~ a::l₂ ↔ l₁ <+~ l₂ :=
⟨λ ⟨l, p, s⟩, begin
  cases s with _ _ _ s' u _ _ s',
  { exact (p.subperm_left.2 $ subperm_of_sublist $ sublist_cons _ _).trans
     (subperm_of_sublist s') },
  { exact ⟨u, perm_cons_inv p, s'⟩ }
end, λ ⟨l, p, s⟩, ⟨a::l, skip a p, s.cons2 _ _ _⟩⟩

theorem subperm_app_left {l₁ l₂ : list α} : ∀ l, l++l₁ <+~ l++l₂ ↔ l₁ <+~ l₂
| []     := iff.rfl
| (a::l) := (subperm_cons a).trans (subperm_app_left l)

theorem subperm_app_right {l₁ l₂ : list α} (l) : l₁++l <+~ l₂++l ↔ l₁ <+~ l₂ :=
(perm_app_comm.subperm_left.trans perm_app_comm.subperm_right).trans (subperm_app_left l)

theorem subperm.exists_of_length_lt {l₁ l₂ : list α} :
  l₁ <+~ l₂ → length l₁ < length l₂ → ∃ a, a :: l₁ <+~ l₂
| ⟨l, p, s⟩ h :=
  suffices length l < length l₂ → ∃ (a : α), a :: l <+~ l₂, from
  exists_imp_exists (λ a, (skip a p).subperm_right.1) $
    this $ perm_length p.symm ▸ h,
  begin
    clear subperm.exists_of_length_lt p h l₁, rename l₂ u,
    induction s with _ _ _ s IH _ _ b s IH; intro h,
    { cases h },
    { cases lt_or_eq_of_le (nat.le_of_lt_succ h : length l₁ ≤ length l₂) with h h,
      { refine exists_imp_exists _ (IH h),
        exact λ a s, s.trans (subperm_of_sublist $ sublist_cons _ _) },
      { exact ⟨a, eq_of_sublist_of_length_eq s h ▸ subperm.refl _⟩ } },
    { refine exists_imp_exists _ (IH $ nat.lt_of_succ_lt_succ h),
      exact λ a s, (swap _ _ _).subperm_right.1 ((subperm_cons _).2 s) }
  end

theorem subperm_of_subset_nodup
  {l₁ l₂ : list α} (d : nodup l₁) (H : l₁ ⊆ l₂) : l₁ <+~ l₂ :=
begin
  induction d with a l₁' h d IH,
  { exact ⟨nil, perm.nil, nil_sublist _⟩ },
  { cases forall_mem_cons.1 H with H₁ H₂, simp at h,
    rcases IH H₂ with ⟨l₂', p, s⟩, clear IH H H₂ l₁,
    induction s with r₁ r₂ b s' IH r₁ r₂ b s' IH generalizing l₁',
    { cases H₁ },
    { simp at H₁, cases H₁ with e m,
      { subst b, exact ⟨a::r₁, skip a p, s'.cons2 _ _ _⟩ },
      { exact let ⟨t, p', s'⟩ := IH m d h p in ⟨t, p', s'.cons _ _ _⟩ } },
    { have bm : b ∈ l₁' := (perm_subset p $ mem_cons_self _ _),
      have am : a ∈ r₂ := H₁.resolve_left (λ e, h $ e.symm ▸ bm),
      rcases mem_split bm with ⟨t₁, t₂, e⟩, subst l₁',
      have st : t₁ ++ t₂ <+ t₁ ++ b :: t₂ := by simp,
      rcases IH am (nodup_of_sublist st d)
        (mt (λ x, subset_of_sublist st x) h)
        (perm_cons_inv $ p.trans perm_middle) with ⟨t, p', s'⟩,
      exact ⟨b::t, (skip b p').trans $
        (swap _ _ _).trans (skip a perm_middle.symm), s'.cons2 _ _ _⟩ } }
end

theorem perm_ext {l₁ l₂ : list α} (d₁ : nodup l₁) (d₂ : nodup l₂) : l₁ ~ l₂ ↔ ∀a, a ∈ l₁ ↔ a ∈ l₂ :=
⟨λ p a, mem_of_perm p, λ H, subperm.antisymm
  (subperm_of_subset_nodup d₁ (λ a, (H a).1))
  (subperm_of_subset_nodup d₂ (λ a, (H a).2))⟩

section
variable [decidable_eq α]

-- attribute [congr]
theorem erase_perm_erase (a : α) {l₁ l₂ : list α} (p : l₁ ~ l₂) :
  l₁.erase a ~ l₂.erase a :=
if h₁ : a ∈ l₁ then
have h₂ : a ∈ l₂, from perm_subset p h₁,
perm_cons_inv $ trans (perm_erase h₁).symm $ trans p (perm_erase h₂)
else
have h₂ : a ∉ l₂, from mt (mem_of_perm p).2 h₁,
by rw [erase_of_not_mem h₁, erase_of_not_mem h₂]; exact p

theorem perm_diff_left {l₁ l₂ : list α} (t : list α) (h : l₁ ~ l₂) : l₁.diff t ~ l₂.diff t :=
by induction t generalizing l₁ l₂ h; simp [*, erase_perm_erase]

theorem perm_diff_right (l : list α) {t₁ t₂ : list α} (h : t₁ ~ t₂) : l.diff t₁ ~ l.diff t₂ :=
by induction h generalizing l; simp [*, erase_perm_erase, erase_comm]
  <|> exact (ih_1 _).trans (ih_2 _)

theorem cons_perm_iff_perm_erase {a : α} {l₁ l₂ : list α} : a::l₁ ~ l₂ ↔ a ∈ l₂ ∧ l₁ ~ l₂.erase a :=
⟨λ h, have a ∈ l₂, from perm_subset h (mem_cons_self a l₁),
      ⟨this, perm_cons_inv $ h.trans $ perm_erase this⟩,
 λ ⟨m, h⟩, trans (skip a h) (perm_erase m).symm⟩

theorem perm_iff_count {l₁ l₂ : list α} : l₁ ~ l₂ ↔ ∀ a, count a l₁ = count a l₂ :=
⟨perm_count, λ H, begin
  induction l₁ with a l₁ IH generalizing l₂,
  { cases l₂ with b l₂, {refl},
    specialize H b, simp at H, contradiction },
  { have : a ∈ l₂ := count_pos.1 (by rw ← H; simp; apply nat.succ_pos),
    refine trans (skip a $ IH $ λ b, _) (perm_erase this).symm,
    specialize H b,
    rw perm_count (perm_erase this) at H,
    by_cases b = a; simp [h] at H ⊢; [injection H, assumption] }
end⟩

instance decidable_perm : ∀ (l₁ l₂ : list α), decidable (l₁ ~ l₂)
| []      []      := is_true $ perm.refl _
| []      (b::l₂) := is_false $ λ h, by have := eq_nil_of_perm_nil h; contradiction
| (a::l₁) l₂      := by have := decidable_perm l₁ (l₂.erase a);
                        exact decidable_of_iff' _ cons_perm_iff_perm_erase

-- @[congr]
theorem perm_erase_dup_of_perm {l₁ l₂ : list α} (p : l₁ ~ l₂) :
  erase_dup l₁ ~ erase_dup l₂ :=
perm_iff_count.2 $ λ a,
if h : a ∈ l₁
then by simp [nodup_erase_dup, h, perm_subset p h]
else by simp [h, mt (mem_of_perm p).2 h]

-- attribute [congr]
theorem perm_insert (a : α)
  {l₁ l₂ : list α} (p : l₁ ~ l₂) : insert a l₁ ~ insert a l₂ :=
if h : a ∈ l₁
then by simpa [h, perm_subset p h] using p
else by simpa [h, mt (mem_of_perm p).2 h] using skip a p

theorem perm_insert_swap (x y : α) (l : list α) :
  insert x (insert y l) ~ insert y (insert x l) :=
begin
  by_cases x ∈ l with xl; by_cases y ∈ l with yl; simp [xl, yl],
  by_cases x = y with xy, { simp [xy] },
  simp [not_mem_cons_of_ne_of_not_mem xy xl,
        not_mem_cons_of_ne_of_not_mem (ne.symm xy) yl],
  constructor
end

theorem perm_union_left {l₁ l₂ : list α} (t₁ : list α) (h : l₁ ~ l₂) : l₁ ∪ t₁ ~ l₂ ∪ t₁ :=
begin
  induction h with a l₁ l₂; try {simp},
  exact perm_insert _ ih_1,
  apply perm_insert_swap,
  exact ih_1.trans ih_2
end

theorem perm_union_right (l : list α) {t₁ t₂ : list α} (h : t₁ ~ t₂) : l ∪ t₁ ~ l ∪ t₂ :=
by induction l; simp [*, perm_insert]

-- @[congr]
theorem perm_union {l₁ l₂ t₁ t₂ : list α} (p₁ : l₁ ~ l₂) (p₂ : t₁ ~ t₂) : l₁ ∪ t₁ ~ l₂ ∪ t₂ :=
trans (perm_union_left t₁ p₁) (perm_union_right l₂ p₂)

theorem perm_inter_left {l₁ l₂ : list α} (t₁ : list α) : l₁ ~ l₂ → l₁ ∩ t₁ ~ l₂ ∩ t₁ :=
perm_filter _

theorem perm_inter_right (l : list α) {t₁ t₂ : list α} (p : t₁ ~ t₂) : l ∩ t₁ = l ∩ t₂ :=
by dsimp [(∩), list.inter]; congr;
   exact funext (λ a, propext $ mem_of_perm p)

-- @[congr]
theorem perm_inter {l₁ l₂ t₁ t₂ : list α} (p₁ : l₁ ~ l₂) (p₂ : t₁ ~ t₂) : l₁ ∩ t₁ ~ l₂ ∩ t₂ :=
perm_inter_right l₂ p₂ ▸ perm_inter_left t₁ p₁
end

theorem perm_pairwise {R : α → α → Prop} (S : symmetric R) :
  ∀ {l₁ l₂ : list α} (p : l₁ ~ l₂), pairwise R l₁ ↔ pairwise R l₂ :=
suffices ∀ {l₁ l₂}, l₁ ~ l₂ → pairwise R l₁ → pairwise R l₂, from λ l₁ l₂ p, ⟨this p, this p.symm⟩,
λ l₁ l₂ p d, begin
  induction d with a l₁ h d IH generalizing l₂,
  { rw eq_nil_of_perm_nil p, constructor },
  { have : a ∈ l₂ := perm_subset p (mem_cons_self _ _),
    rcases mem_split this with ⟨s₂, t₂, e⟩, subst e,
    have p' := perm_cons_inv (p.trans perm_middle),
    refine (pairwise_middle S).2 (pairwise_cons.2 ⟨λ b m, _, IH _ p'⟩),
    exact h _ (perm_subset p'.symm m) }
end

theorem perm_nodup {l₁ l₂ : list α} : l₁ ~ l₂ → (nodup l₁ ↔ nodup l₂) :=
perm_pairwise $ @ne.symm α

theorem perm_bind_left {l₁ l₂ : list α} (f : α → list β) (p : l₁ ~ l₂) :
  l₁.bind f ~ l₂.bind f :=
begin
  induction p with a l₁ l₂ p IH a b l l₁ l₂ l₃ p₁ p₂ IH₁ IH₂, {simp},
  { simp, exact perm_app_right _ IH },
  { simp, rw [← append_assoc, ← append_assoc], exact perm_app_left _ perm_app_comm },
  { exact trans IH₁ IH₂ }
end

theorem perm_bind_right (l : list α) {f g : α → list β} (h : ∀ a, f a ~ g a) :
  l.bind f ~ l.bind g :=
by induction l with a l IH; simp; exact perm_app (h a) IH

theorem perm_product_left {l₁ l₂ : list α} (t₁ : list β) (p : l₁ ~ l₂) : product l₁ t₁ ~ product l₂ t₁ :=
perm_bind_left _ p

theorem perm_product_right (l : list α) {t₁ t₂ : list β} (p : t₁ ~ t₂) : product l t₁ ~ product l t₂ :=
perm_bind_right _ $ λ a, perm_map _ p

@[congr] theorem perm_product {l₁ l₂ : list α} {t₁ t₂ : list β}
  (p₁ : l₁ ~ l₂) (p₂ : t₁ ~ t₂) : product l₁ t₁ ~ product l₂ t₂ :=
trans (perm_product_left t₁ p₁) (perm_product_right l₂ p₂)

end list
