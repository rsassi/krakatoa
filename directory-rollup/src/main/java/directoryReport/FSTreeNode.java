package directoryReport;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class FSTreeNode<T> {

    List<FSTreeNode<T>> children;
    String name;
    T data;
    String path;

    public FSTreeNode(String name, String path) {
        this.children = new ArrayList<FSTreeNode<T>>();
        this.name = name;
        this.path = path;
    }

    public FSTreeNode(String name, String path, T data) {
        this.children = new ArrayList<FSTreeNode<T>>();
        this.name = name;
        this.data = data;
        this.path = path;
    }

    public boolean isLeaf() {
        return children.isEmpty();
    }

    public void add(String currentPath, String[] list, T data) {
        // Skip empty string. This occurs when path has a starting slash like
        // "/tmp/"
        while (list[0] == null || list[0].equals(""))
            list = Arrays.copyOfRange(list, 1, list.length);

        String path = currentPath.isEmpty() ? list[0] : currentPath + "/"
                + list[0];
        FSTreeNode<T> child = new FSTreeNode<T>(list[0], path);
        {
            // Does the child already exists?
            int index = children.indexOf(child);
            if (index == -1) { // no, add it
                children.add(child);
            } else {// yes
                child = children.get(index);
            }
            // make sure we add children if there are any
            if (list.length == 1) {
                // leaf node!
                child.data = data;
            } else {
                child.add(child.path, Arrays.copyOfRange(list, 1, list.length),
                        data);
            }
        }
    }

    @Override
    public boolean equals(Object obj) {
        @SuppressWarnings("unchecked")
        FSTreeNode<T> cmpObj = (FSTreeNode<T>) obj;
        return path.equals(cmpObj.path) && name.equals(cmpObj.name);
    }

    @Override
    public String toString() {
        if (null == data) {
            return "(" + path + ", " + name + ", null)";
        } else {
            return "(" + path + ", " + name + ", " + data + ")";
        }
    }

    public FSTreeIterator<T> iterator() {
        return new FSTreeIterator<T>(this);
    }

}