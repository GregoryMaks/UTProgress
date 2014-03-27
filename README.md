UTProgress
==========

UTProgress is class that can be used to mimic NSProgress functionality for hierarchical progress tracking.

<h4>UTProgress vs NSProgress</h4>

<h5>Pros:</h5>
<ul>
<li>One current NSProgress per thread, UTProgress is not linked to the thread</li>
<li>NSProgress cannot be used when using CoreData in the same thread, current progress values can be unexpectedly changed by CoreData</li>
</ul>

<h5>Cons:</h5>
<ul>
<li>Should be transferred to method manually, no convenient <i>[Progress currentProgress]</i> method</li>
</ul>
