Require Import veric.base.
Require Import msl.normalize.
Require Import msl.rmaps.
Require Import msl.rmaps_lemmas.
Require Import veric.compcert_rmaps.
Require Import msl.msl_standard.
Require Import veric.res_predicates.
Require Import veric.seplog.
Require Import veric.tycontext.
Require Import veric.expr2.
Require Import veric.expr_lemmas.

Definition size_compatible {C: compspecs} t p :=
  match p with
  | Vptr b i_ofs => Int.unsigned i_ofs + sizeof cenv_cs t <= Int.modulus
  | _ => True
  end.

Lemma nonlock_permission_bytes_valid_pointer: forall sh b ofs n i,
  0 <= ofs /\ ofs + n <= Int.modulus ->
  0 <= i < n ->
  nonidentity sh ->
  nonlock_permission_bytes sh (b, ofs) n |-- valid_pointer (Vptr b (Int.repr (ofs + i))).
Proof.
  intros.
  unfold nonlock_permission_bytes, valid_pointer.
  intros w ?.
  simpl in H2 |- *.
  rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
  rewrite Z.add_0_r.
  specialize (H2 (b, ofs + i)).
  if_tac in H2.
  + destruct H2.
    destruct (w @ (b, ofs + i)); inv H2; inv H4; auto.
    apply nonidentity_rel_Lsh; auto.
  + exfalso.
    simpl in H3.
    apply H3.
    split; auto.
    omega.
Qed.

Lemma VALspec_range_valid_pointer: forall rsh sh b ofs n i,
  0 <= ofs /\ ofs + n <= Int.modulus ->
  0 <= i < n ->
  VALspec_range n rsh sh (b, ofs) |-- valid_pointer (Vptr b (Int.repr (ofs + i))).
Proof.
  intros.
  unfold VALspec_range, valid_pointer.
  intros w ?.
  simpl in H1 |- *.
  rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
  rewrite Z.add_0_r.
  specialize (H1 (b, ofs + i)).
  if_tac in H1.
  + destruct H1 as [? [? ?]].
    rewrite H1; auto.
  + exfalso.
    simpl in H2.
    apply H2.
    split; auto.
    omega.
Qed.

Lemma address_mapsto_valid_pointer: forall ch v rsh sh b ofs i,
  0 <= ofs /\ ofs + size_chunk ch <= Int.modulus ->
  0 <= i < size_chunk ch ->
  address_mapsto ch v rsh sh (b, ofs) |-- valid_pointer (Vptr b (Int.repr (ofs + i))).
Proof.
  intros.
  eapply derives_trans; [apply address_mapsto_VALspec_range |].
  apply VALspec_range_valid_pointer; auto.
Qed.

Lemma mapsto_valid_pointer: forall {cs: compspecs} sh t p v i,
  size_compatible t p ->
  0 <= i < sizeof cenv_cs t ->
  nonidentity sh ->
  mapsto sh t p v |-- valid_pointer (offset_val (Int.repr i) p).
Proof.
  intros.
  unfold mapsto.
  destruct (access_mode t) eqn:?H; auto.
  destruct (type_is_volatile t); auto.
  destruct p; auto.
  destruct (readable_share_dec sh).
  + apply orp_left; apply andp_left2.
    - simpl in H.
      erewrite size_chunk_sizeof in H by eauto.
      erewrite size_chunk_sizeof in H0 by eauto.
      pose proof Int.unsigned_range i0.
      apply address_mapsto_valid_pointer.
      * omega.
      * rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
        omega.
    - apply exp_left; intro.
      simpl in H.
      erewrite size_chunk_sizeof in H by eauto.
      erewrite size_chunk_sizeof in H0 by eauto.
      pose proof Int.unsigned_range i0.
      apply address_mapsto_valid_pointer.
      * omega.
      * rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
        omega.
  + simpl in H.
    erewrite size_chunk_sizeof in H by eauto.
    erewrite size_chunk_sizeof in H0 by eauto.
    pose proof Int.unsigned_range i0.
    apply nonlock_permission_bytes_valid_pointer.
    - omega.
    - rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
      omega.
    - auto.
Qed.

Lemma memory_block_valid_pointer: forall {cs: compspecs} sh n p i,
  0 <= i < n ->
  nonidentity sh ->
  memory_block sh n p |-- valid_pointer (offset_val (Int.repr i) p).
Proof.
  intros.
  unfold memory_block.
  destruct p; auto.
  normalize.
  pose proof Int.unsigned_range i0.
  rewrite memory_block'_eq.
  2: omega.
  2: rewrite Z2Nat.id; omega.
  unfold memory_block'_alt.
  rewrite Z2Nat.id by omega.
  destruct (readable_share_dec sh).
  + apply VALspec_range_valid_pointer.
    - omega.
    - rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
      auto.
  + apply nonlock_permission_bytes_valid_pointer.
    - omega.
    - rewrite Int.unsigned_repr by (unfold Int.max_unsigned; omega).
      omega.
    - auto.
Qed.



