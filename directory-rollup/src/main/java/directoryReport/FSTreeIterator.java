package directoryReport;

/* an iterator class to iterate over nary trees
 */

import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Stack;

/**
 * This iterator will remain valid as long 
 * as the parents of the node are not removed from the tree.
 * @author eseprud
 *
 * @param <T>
 */
public class FSTreeIterator<T> implements Iterator<T> {
    protected FSTreeNode<T> root = null;
    protected Stack<FSTreeNode<T>> visiting = new Stack<>();
    protected Stack<Integer> depthStack = new Stack<>();
    Integer currentDepth = 0;
    FSTreeNode<T> currentFSNode;

    public FSTreeIterator(FSTreeNode<T> root) {
        this.root = root;
        visiting = new Stack<FSTreeNode<T>>();
        // setup the visiting stack
        visiting.push(root);
        depthStack.push(0);
    }

    public boolean hasNext() {
        return (!visiting.empty());
    }

    public int depth() {
        return currentDepth;
    }

    public boolean hasChildren() {
        if (null == currentFSNode) {
            return false;
        }
        return currentFSNode.isLeaf();
    }

    FSTreeNode<T> getNode() {
        return currentFSNode;
    }

    public T next() {
        if (!hasNext()) {
            throw new java.util.NoSuchElementException("no more elements");
        }
        currentFSNode = visiting.pop();
        Integer depth = depthStack.pop();
        currentDepth = depth;
        depth++;
        for (@SuppressWarnings("unused")
        FSTreeNode<T> child : currentFSNode.children) {
            depthStack.push(depth);
        }
        List<FSTreeNode<T>> list = new LinkedList<>();
        list.addAll(currentFSNode.children);
        Collections.reverse(list);
        visiting.addAll(list);
        return currentFSNode.data;
    }

    public void remove() {
        throw new java.lang.UnsupportedOperationException("remove");
    }

    public String toString() {
        return "stack" + visiting + "\n";
    }

}