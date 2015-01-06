> module Comb where

> import Data.List
> import Data.Char

> import Flo
> import Misc


*** Permute

**** TODO wire_vec variant with second arg 0


Creates a module with size inputs and outputs that reorders the inputs
according to the specified function fn which should be bijective (?)

> {-permute name fn size = make_block ("permute_"++name++"_"++(show size)) (wire_vec "i" 0 size) (wire_vec "o" 0 size)
>                        (map (\i->inst_block pblk_id [("i"++(show i)),("o"++(show (fn size i)))]) [0..(size-1)]) -}

> {-chain2 port0 port1 wire_prefix inst_blocks = map (\(inst_block,i)-> attach_v inst_block [port0,port1]
>                                                                     [wire_prefix++(show i),wire_prefix++(show (i+1))])
>                                              (zip inst_blocks [0..]) -}

> {-chain_old port0 port1 wires inst_blocks = zipWith3 (\w0 w1 inst_block-> attach_v inst_block [port0,port1] [w0,w1])
>                                       wires (tail wires) inst_blocks -}

> ---Combinators

Combinators to do:

1. vector
2. chain
3. complete tree
4. arb (full?) bintree (arity>2?)
5. xbintree (arity>2?)
6. butterfly
7. parallel prefix (one or more)
8. transpose?
9. wallace tree?
10. cordic?

> --combinators

> replace_elem list elem elem' = map (\e->if e == elem then elem' else e) list
> replace_elems list elems elems' = foldr (\(e,e') r->replace_elem r e e') list (zipWith (,) elems elems')
>
> {-join :: [Char]->Block->Block->[[Char]]->[[Char]]->[[Char]]->Block
> join name blk0 blk1 adj0 adj1 com = 
>   make_block name (com++(((in_ports_ blk0)\\com)\\adj0)++(((in_ports_ blk1)\\com)\\adj1))
>                (((out_ports_ blk0)\\adj0)++((out_ports_ blk1)\\adj1))
>                [inst_block blk0 (replace_elems ((in_ports_ blk0)++(out_ports_ blk0)) adj0 (wire_vec "_t" 0 (length adj0))),
>                 inst_block blk1 (replace_elems ((in_ports_ blk1)++(out_ports_ blk1)) adj1 (wire_vec "_t" 0 (length adj1)))] -}
>
> -- chain::Block->[{Char]]->[{Char]]->Int->Block
> {- chain block com_in adj size =
>   let vec_in = ((in_ports_ block) \\ com_in) \\ adj
>       adj_in = intersect (in_ports_ block) adj
>       vec_out = ((out_ports_ block) \\ com_in) \\ adj
>       adj_out = intersect (out_ports_ block) adj
>       adj_wires = (adj_in++(concatMap (\n->(zipWith (\i o ->i++o++"_"++(show n)) adj_in adj_out)) [0..(size-2)])++adj_out)
>   in  make_block ((name_ block)++"_chain_"++(show size)) (com_in ++ (concatMap (\p->wire_vec p 0 size) vec_in) ++ adj_in)
>         ((concatMap (\p->wire_vec p 0 size) vec_out) ++ adj_out)
>         (zipWith3 (\i o n->(inst_block block (com_in++(map (\p->p++(show n)) vec_in)++[i]++
>                                               (map (\p->p++(show n)) vec_out)++[o])))
>          (init adj_wires) (tail adj_wires) [0..(size-1)]) -}

**** TODO <2013-06-23 Sun>

     Need to add info from blk0 com_in and adj into the module name to avoid
     name clashes.
    

> _chain' pre blk blk0 adj vports i b = make_block (pre++(name_ blk)++"_"++(show (i+1)))
>                                        (ports_vec (in_ports_ blk0) vports (i+1)) (ports_vec (out_ports_ blk0) vports (i+1))
>                                        [inst_block blk (ports_vec_i (io_ports blk) vports i),
>                                         inst_block b (ports_vec (replace_elems (io_ports blk0)
>                                                                  (intersect (out_ports_ blk0) adj)
>                                                                  (intersect (in_ports_ blk) adj)) vports i)]

> chain' blk blk0 com_in adj size = foldr (_chain' "" blk blk0 adj (((io_ports blk)\\com_in)\\adj)) blk0
>                                   (reverse [1..(size-1)])


> chain0' blk com_in size = chain' blk blk com_in [] size

*** chain variants with prefix <2013-06-29 Sat>

    Solution to the nameclash problem: chain' and chain0' variants with prefix
    argument. Also had to modify _chain' to add the prefix (pre) argument, and
    chain' and chain0' to pass "" as the pre argument.

> chain'' pre blk blk0 com_in adj size = foldr (_chain' pre blk blk0 adj (((io_ports blk)\\com_in)\\adj)) blk0
>                                         (reverse [1..(size-1)])

> chain0'' pre blk com_in size = chain'' pre blk blk com_in [] size


TODO: Move chain* to Flo module?

**** TODO Resolve module name clash between chain' and xbintree_arb for mqueue
     In general, how to avoid name clashes between modules generated by
     different combinators, or even same combinator, for eg. chain' can be
     called twice with same args except list of global signals...

**** TODO chain' problem when size=1 <2012-06-01 Fri>
     Problem is that portnames are different: eg., i0 when size=1 and i00 when
     size>1. Normally, seems okay if ports used immediately but if generated
     block is further used in a combi, for eg., chain' again, then assumption
     of name i00 when name is i0 causes problems (as in nested chain' mux2 in
     mqueue1).
     If one assumes that size=1 occurs only when block 0 (blk0) is same as
     other blocks...
     Solution(?): Make wires behave same way...

**** TODO chain' with size=0 <2012-06-01 Fri>
     At times chain' is required to give a "meaningful/useful" result when
     size=0 (eg. mqueue with words=tag_size). So perhaps blk0 can be used for
     that. Also a "nil" block seems to be required (analogous to []). Doing so,
     of course raises the issue of what to do with "chain' fa ha..." kind of
     invocations where blk0 is used for ha.


Assumed that only difference between ports of blk0 and other blocks is
that blk0 has no "cin" type ports. And so it is hoped that replacing
blk by blk0 in (((io_ports blk)\\com_in)\\adj) should be fine.

Okay, chain finally seems to have the right (probably just cleaner)
abstraction. The code could be cleaner if ports are generated using
the ports of b instead of starting from scratch as done now. The
improvement requires being able to increment by one the vector ports
in input ports list. Writing a function for it seems a bit painful,
but there may be a more generally useful abstraction lurking in there
(and likely more compact chain:)).

Abstraction seems to break for addsubv: how to connect common signal
addsub to "cin" input of blk0?

TODO: Rewrite chain' in terms of chain.
TODO: Rewrite ncopy[?] in terms of chain.

Latest (hopefully (almost) final) idea is to use a "hylomorphism" as
the origin for all linear (array like) structures. We start with the
most general, where the hylo unfold produces a list of pairs, each a
pair composed of a block and a tuple composed of com_in, left and
right ports for the block. Per block ports seems similar to above idea
so hopefully we're on the right track...

So, how to right the e (lets call it chn (for now)) for the hylo? Lets try:

Attributes:
1. Array structure base name
2. Instance appended name (else default instance number (starting from 0))
3. Bidir adjacent (else unidir)
4, Explicit block list (else ?)
5. Adj list (else none)
6. z parameter

>{-- chn name comi (blk,iname,(bl,br)) (i,prev_bl,cur_chain,ci,co) =
>   let bi = (((in_ports_ blk)\\com_in)\\bl)\\br
>       bo = ((in_ports_ blk)\\bl)\\br
>   in (i+1, make_block (name++"_"++iname) (comi++((bl)\\(out_ports_ blk))++bi++ci) (((bl)\\(in_ports_ blk))++bo++co)
>       [inst_block blk (ports_vec_i (io_ports blk) (bi++bo) i),
>        inst_block cur_chain (comi++(prev_bl\\(out_ports_ cur_chain)) ]) --}

> {-chn' name comi (blk,iname,lki,lko,rki,rko,ki,ko) (k,cur_chain,lkm1i,lkm1o,r0i,r0o,km10i_,km10o_) =
>   (k,make_block (name++"_"++iname) (comi++lki++r0i++(ports_vec_i' ki k)++km10i_) (lko++r0o++(ports_vec_i' ko k)++km10o_)
>    [inst_block blk (comi++lki++rki++(ports_vec_i' ki k)++lko++rko++(ports_vec_i' ko k)),
>     inst_block cur_chain (comi++rko++r0i++km10i_++rki++r0o++km10o_)],
>    lki,lko,r0i,r0o,(ports_vec_i' ki k)++km10i_,(ports_vec_i' ko k)++km10o_) -}

Partition ports of each blk in list.

> --part_ports comi l = foldr (part_ports' comi) [] l

> {-part_ports comi (blk,iname,lk,rk) = (blk,iname,(intersect lk (in_ports_ blk)),(intersect lk (out_ports_ blk)),
>                                      (intersect rk (in_ports_ blk)),(intersect rk (out_ports_ blk)),
>                                      (inports_ blk)\\(comi++lk++rk),(outports_ blk)\\(lk++rk)) -}

> {-blk0_ports (blk,iname,lki,lko,rki,rko,ki,ko) = (blk,iname,lki,lko,rki,rko,(ports_vec_i' 0 ki),(ports_vec_i' 0 ko)) -}

> {-chn name comi b0 p f g x = foldr (chn' name comi) (blk0_ports (part_ports comi b0)) (unfold p f g x) -}

> {-chn_u name comi b0 p f g x =
>   let (blk,iname,adj) = \x->(f x)
>   in chn name comi b0 p (\x->(blk,iname,(intersect adj (in_ports_ blk)),(intersect adj) (out_ports_ blk))) g x -}

> {-chn_uw name comi b0 p f g x = let (blk,iname) = \x->(f x) in chn_u name comi b0 p (\(adj,y)->(blk,iname,adj)) g x -}

> {-chn_uwm name comi b0 p f g x = let iname = \x->(f x) in chn_uw name comi b0 p (\(blk,adj,y)->(blk,iname)) (g x -}

> {-chn_uwmn name comi b0 p g x = let iname = \x->(f x) in chn_uwm name comi b0 p (\(iname,blk,adj,y)->iname) g x -}

> {-chain0 name com_in adj (j,blk) (i,b) = 
>   let vports = (((io_ports blk)\\com_in)\\adj)
>   in (i+1, make_block (name++"_"++j) (ports_vec ((in_ports_ blk)\\adj) vports (i+1))
>       (ports_vec (out_ports_ blk) vports (i+1))
>       [inst_block blk (ports_vec_i (io_ports blk) vports i),
>        inst_block b (ports_vec (replace_elems (((in_ports_ blk)\\adj)++(out_ports_ blk))
>                                 (intersect (out_ports_ blk) adj) (intersect (in_ports_ blk) adj)) vports (i))]) -}
>
> {-chain name com_in adj blk0 blks = snd (foldr (chain0 name com_in adj) (0,blk0) blks) -}

> wire_vec prefix start size = map (\i-> prefix ++ (show i)) [start..(start+size-1)]

> wires prefix start size = map (\i-> prefix ++ (show i)) [start..(start+size-1)]

> wires0 prefix size = wires prefix 0 size

_wires2 functionality seems useful, so separated it out from wires. <2013-07-01 Mon>

> _wires2 prefix start0 size0 start1 size1 = map2 (\i j-> prefix++(show i)++"_"++(show j)) [start0..(start0+size0-1)]
>                                                  [start1..(start1+size1-1)]

> _wires2_0 prefix size0 size1 = _wires2 prefix 0 size0 0 size1


> wires2 prefix start0 size0 start1 size1 = concat (_wires2 prefix start0 size0 start1 size1)

wires2l didn't seem useful...<2013-06-30 Sun>

> {-wires2l list start size = concat (map2 (\i j-> i++"_"++(show j)) list [start..(start+size-1)])
> wires2l0 list size = concat (map2 (\i j-> i++"_"++(show j)) list [0..(size-1)])-}

> wires2_1 prefix start0 size0 size1 = wires2 prefix start0 size0 0 size1

> wires2_0 prefix size0 size1 = wires2 prefix 0 size0 0 size1

> wires2' prefix start0 size0 start1 size1 = concat (transpose (map2 (\i j-> prefix++(show i)++"_"++(show j)) [start0..(start0+size0-1)]
>                                                   [start1..(start1+size1-1)]))

> wires2'_1 prefix start0 size0 size1 = wires2' prefix start0 size0 0 size1

> wires2'_0 prefix size0 size1 = wires2' prefix 0 size0 0 size1

Following needed due to chain' portname problem when size=1.
**** TODO Can wires' replace wires? <2012-06-01 Fri>

> wires' prefix start size = if size==1 then [prefix] else wires prefix start size

> wires0' prefix size = if size==1 then [prefix] else wires0 prefix size

> ---block!=nil, arity>1, levels>=0 (level 0 returns pblk_id)
> tree_complete block arity levels = foldr (tree_complete_1 block ((name_ block)++"_"++(show arity)) arity
>                                             (length (out_ports_ block))) pblk_id (reverse [1..levels])

> tree_complete_1 node_blk name_prefix arity width level tree_blk =
>   make_block (name_prefix++"_"++(show level)) (wire_vec "i" 0 (width*(arity^(level)))) (wire_vec "o" 0 width)
>                ((inst_block node_blk ((wire_vec "_t" 0 (arity*width))++(wire_vec "o" 0 width))):
>                 (map (\i->inst_block tree_blk ((wire_vec "i" (i*width*(arity^(level-1))) (width*(arity^(level-1))))++
>                                                (wire_vec "_t" (i*width) width))) [0..(arity-1)]))

> jwidth block arity = (length (in_ports_ block)) - ((length (out_ports_ block))*arity)

Seems to work out quite well: since level is 0 for pblk_id, the j
inputs to it disappear as the number of j inputs is jwidth*(level-1)

Seems xtree* performs functionality of tree*, so delete latter? Also
chain performs functionality of vec? Or better to define vec in terms
of chain? And tree in terms of xtree?

Why use pblk_id in tree and xtree? Simplifies code (else if statement
would be required). Also gives a (hopefully) useful output for level=0
which may be useful in some situations. More importantly, the
[x]bintree_arb function, in order to construct a [x]tree with
arbitrary inputs, uses pblk_id as a [x]tree with one input. While
[x]trees with arbitrary input could be constructed without a [x]tree
of one input, the ability to do so is convenient as it simplifies
code. Again, it also enables [x]bintree_arb to return something
(hopefully) useful when asked to return a [x]tree with one input.


> xtree_complete block arity levels = foldr (xtree_complete_1 block ((name_ block)++"_"++(show arity)) arity
>                                             (length (out_ports_ block)) (jwidth block arity)) pblk_id (reverse [1..levels])

**** TODO <2012-12-20 Thu>
     pblk_id in xtree_complete seems to work only for width 1. Seems need to
     replace with (chain'0 pblk_id (length (out_ports_ block)).

> xtree_complete_1 node_blk name_prefix arity width jwidth level tree_blk =
>   make_block (name_prefix++"_"++(show level)) ((wire_vec "i" 0 (width*(arity^level)))++
>                                                (wire_vec "j" 0 (jwidth*level))) (wire_vec "o" 0 width)
>                ((inst_block node_blk ((wire_vec "_t" 0 (arity*width))++(wire_vec "j" (jwidth*(level-1)) jwidth)++(wire_vec "o" 0 width))):
>                 (map (\i->inst_block tree_blk ((wire_vec "i" (i*width*(arity^(level-1))) (width*(arity^(level-1))))++
>                                                (wire_vec "j" 0 (jwidth*(level-1)))++
>                                                (wire_vec "_t" (i*width) width))) [0..(arity-1)]))

> compose_bintree node_blk width (ltree_blk,l_level) (rtree_blk,r_level) =
>     (make_block "" (wire_vec "i" 0 (width*((2^l_level)+(2^r_level)))) (wire_vec "o" 0 width)
>                  [inst_block node_blk ((wire_vec "_t" 0 (2*width))++(wire_vec "o" 0 (width))),
>                   inst_block ltree_blk ((wire_vec "i" 0 (width*(2^l_level)))++(wire_vec "_t" 0 (width))),
>                   inst_block rtree_blk ((wire_vec "i" (width*(2^l_level)) (2^r_level))++(wire_vec "_t" width (width)))],
>      (max l_level r_level)+1)

> bintree_arb block inputs = foldl1 (compose_bintree block (length (out_ports_ block)))
>                            (unfold (0 ==) (\x->(tree_complete block 2 (log2_floor x), (log2_floor x)))
>                                            (\x-> x - (2^(log2_floor x))) inputs)


It is assumed that the left subtree is larger than the right one. TODO: Better module name.

> compose_xbintree' node_blk width jwidth (ltree_blk,l_level) (rtree_blk,r_level) =
>   (make_block ((name_ node_blk)++"__"++(show l_level)++"_"++(show r_level))
>    ((wire_vec "i" 0 (width*((2^l_level)+(2^r_level))))++(wire_vec "j" 0 (jwidth*((max l_level r_level)+1))))
>    (wire_vec "o" 0 width)
>    [inst_block node_blk ((wire_vec "_t" 0 (2*width))++(wire_vec "j" (jwidth*l_level) jwidth)++
>                                                       (wire_vec "o" 0 (width))),
>     inst_block ltree_blk ((wire_vec "i" 0 (width*(2^l_level)))++(wire_vec "j" 0
>                                                                  (jwidth*l_level))++(wire_vec "_t" 0 (width))),
>     inst_block rtree_blk ((wire_vec "i" (width*(2^l_level)) (2^r_level))++(wire_vec "j"  (jwidth*(l_level-r_level))
>                                                                            (jwidth*r_level))++
>                           (wire_vec "_t" width (width)))],
>       (l_level+1))

**** TODO
"- jwidth" in l_in_ports and r_in_ports seems right but needs to be checked.

> compose_xbintree node_blk width jwidth (ltree_blk,l_level) (rtree_blk,r_level) =
>   let l_in_ports= length (in_ports_ ltree_blk) - jwidth*l_level
>       r_in_ports= length (in_ports_ rtree_blk) - jwidth*r_level
>   in (make_block ((name_ node_blk)++"__"++(show width)++"_"++(show (div l_in_ports width))++"_"++
>                   (show (div r_in_ports width)))
>       ((wire_vec "i" 0 (l_in_ports+r_in_ports))++(wire_vec "j" 0 (jwidth*((max l_level r_level)+1))))
>       (wire_vec "o" 0 width)
>       [inst_block node_blk ((wire_vec "_t" 0 (2*width))++(wire_vec "j" (jwidth*l_level) jwidth)++
>                             (wire_vec "o" 0 width)),
>        inst_block ltree_blk ((wire_vec "i" 0 (width*l_in_ports))++(wire_vec "j" 0
>                                                                    (jwidth*l_level))++(wire_vec "_t" 0 width)),
>        inst_block rtree_blk ((wire_vec "i" (width*l_in_ports) r_in_ports)++
>                              (wire_vec "j"  (jwidth*(l_level-r_level)) (jwidth*r_level))++(wire_vec "_t" width (width)))],
>       (l_level+1))

> xbintree_arb block inputs = foldl1 (compose_xbintree block (length (out_ports_ block)) (jwidth block 2))
>                             (unfold (0 ==) (\x->(xtree_complete block 2 (log2_floor x), (log2_floor x)))
>                              (\x-> x - (2^(log2_floor x))) inputs)

**** TODO

     If xbintree_arb can "naturally" handle zero inputs, modify it to do so (it
     should, it seems return the zero block when inputs are zero). Also at
     present id block is returned when there's just one input, but at times it
     may be useful to return the gate_invert block (and similarly for zero
     inputs it may be useful to return the one block).

**** TODO <2012-12-20 Thu>
     Why no common ports argument for xbintree_arb? Seems needed for clk, reset
     as in chain...


**** TODO Important idea: Use chain' for multiple inputs in other combinators such as xbintree_arb and par_prefix and thus simplify above combinators by reimplementing for just single wires. <2013-01-05 Sat>
Some mechanism is required to combine the combinators, making them more
powerful <2013-01-07 Mon>.


** Parallel Prefix

**** TODO Arbitary inputs not just 2^n <2013-01-08 Tue>.
     Somewhat like for xbintree. Maybe a higher order function that can capture
     common part of converting 2^n combinators to arb. input combinators
     (perhaps like the unfold in xbintree_arb to which a cpmbinator specific
     function can be passed)).


Determine common ports.

> common_ports block = take ((length (in_ports_ block)) - (2*(length (out_ports_ block)))) (in_ports_ block)

> par_prefix block n = foldr (_par_prefix block (name_ block) (common_ports block) (length (out_ports_ block)))
>                      (chain0' pblk_id [] (length (out_ports_ block))) (reverse [1..n])

> _par_prefix block name_prefix common width i prev_blk =
>   let w p i = map2 (\i j->p++(show i)++"_"++(show j)) [0..((2^i)-1)] [0..(width-1)]
>   in make_block ((name_prefix)++"_par_prefix_"++(show i)++"_"++(show width)++"_"++(show (length common)))
>        (common++(concat(w "i" i))) (concat(w "o" i))
>        [inst_block prev_blk (common++(concat(w "i" (i-1)))++(concat(w "o" (i-1)))),
>         inst_block prev_blk (common++(drop ((2^(i-1))*width) (concat(w "i" i)))++(concat(w "t" (i-1)))),
>         inst_block (chain0' block common (2^(i-1)))
>         (common++(concat (transpose(w "t" (i-1))))++
>          (concat (transpose (replicate (2^(i-1)) (wires0 ("o"++(show ((2^(i-1))-1))++"_") width))))
>          {-++(drop ((2^(i-1))*width) (w "o" (i-1)))-}++(concat(transpose(drop (2^(i-1)) (w "o" i)))))]



norev ports assumed specified in front in lists of input as well as output ports.

> revio norev blk = (((intersect (in_ports_ blk) norev)++((out_ports_ blk)\\norev)),
>                    ((intersect (out_ports_ blk) norev)++((in_ports_ blk)\\norev)))

> blkname_prefix blk = dropWhile isDigit (reverse (name_ blk))

> revio_rec1 norev orgblk blk iblks = if blkname_prefix blk==blkname_prefix orgblk
>                                     then make_block ((name_ blk)++"_r") (fst (revio norev blk)) (snd (revio norev blk))
>                                            (map (\iblk->inst_block iblk ((fst (revio norev blk))++
>                                                                          (snd (revio norev blk)))) iblks)
>                                     else blk -- make_block ((name_ blk)++"_r") (in_ports_ blk) (out_ports_ blk) iblks

> revio_rec norev blk = trav_blocks (revio_rec1 norev blk) id id blk

Current status: Implementation of demux motivated revio_rec which was
intended to reverse not just trees but chains as well (and perhaps
others (like fft?)). But the way wires are connected in xtree and
chain are different. How to resolve? Related issue: add support to
xtree for common wires to left and right subtrees (and node)?

> {- test_mux_n size = let vec_size = size + (log2_ceil size)
>                       sel_ports_commas = add_commas (map (\i->("mod_in["++(show i)++"]"))
>                                                      (reverse [0..(size-1)]))
>                       in_ports_commas = add_commas (map (\i->("mod_in["++(show i)++"]"))
>                                                     (reverse [ size..(vec_size-1)]))
>                   in tb_gen2 ((take (2^vec_size) [0..]))
>                        "$write(\"select input output\\n\\n\");\n"
>                        ("$write(\"%b %b %b\\n\\n\",{"++sel_ports_commas++"},{"++in_ports_commas++"},"++
>                         "mod_out);\n")
>                        (fst (xbintree_arb mux2 size)) tb_comb -}

> -- main = (putStr)  (((fl__ver . fst) (xbintree_arb mux2 |  5))++(test_mux_n 5))

