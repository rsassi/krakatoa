package directoryReport;

public class FSTree<T> {

    FSTreeNode<T> root;

    public FSTree() {
        this.root = new FSTreeNode<T>("", "");
    }

    public void add(String path, T data) {
        if (!path.isEmpty()) {
            String[] list = path.split("/");
            // latest element of the list is the filename.extrension
            root.add(root.path, list, data);
        }
    }

    public void printTree() {
        FSTreeIterator<T> it = iterator();
        while (it.hasNext()) {
            it.next();
            FSTreeNode<T> node = it.getNode();
            for (int i = 0; i < it.depth(); i++) {
                System.out.print(" ");
            }
            System.out.println(node);
        }
    }

    public FSTreeIterator<T> iterator() {
        FSTreeIterator<T> it = new FSTreeIterator<T>(this.root);
        return it;
    }

    // TODO: optimize search time. currently O(n)
    FSTreeNode<T> find(String path) {
        FSTreeIterator<T> it = iterator();
        while (it.hasNext()) {
            it.next();
            FSTreeNode<T> node = it.getNode();
            if (null != node && it.getNode().path.equals(path)) {
                return node;
            }
        }
        return null;
    }

    // -------------------- test code
    public void testIterator() {
        System.out.println("------------------------");
        FSTreeIterator<T> it = iterator();
        System.out.println("it = " + it);
        while (it.hasNext()) {
            T result = it.next();
            System.out.println("it.next data( " + result + ") " + it);
        }
        System.out.println("------------------------");
    }

    private static void test1() {
        String files[] = new String[] { "/a/b/file1.file", "/a",
                "/a/b/x/file2.file", "/a/c/y/file4.file", "/a/b/x/file3.file",
                "/a/c/y/file4.file", "/a/c/z/file5.file", "/a/c/z/file6.file" };

        FSTree<String> tree = new FSTree<String>();
        for (String path : files) {
            tree.add(path, "thedata");
        }
        tree.printTree();
        tree.testIterator();
    }

    private static void test2() {
        String files[] = new String[] { "a/b/file1.file", "a",
                "a/c/y/file4.file", "a/b/x/file2.file", "a/b/x/file3.file",
                "a/c/y/file4.file", "a/c/z/file5.file", "a/c/z/file6.file" };

        FSTree<String> tree = new FSTree<String>();
        for (String path : files) {
            tree.add(path, "thedata");
        }

        tree.printTree();
        tree.testIterator();
    }

    public static void main(String[] args) {
        // TODO: filter empty string in input
        test1();
        System.out.println("----------------------------------------");
        test2();
    }

}