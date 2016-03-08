package directoryReport;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Set;
import java.util.TreeSet;

import com.opencsv.CSVReader;
import com.opencsv.CSVWriter;

public class DirectoryCoverageHtmlReport {
    String dbhost = "";
    String dbport = "";
    String dbname = "";
    String dbuser = "";
    String dbpassword = "";

    String sourceDirFilename = "srcdir.txt";
    String prologueFilename = "collapsing_list.prologue.html";
    String epilogueFilename = "collapsing_list.epilogue.html";

    FSTree<DirectoryCoverage> fsTree = new FSTree<DirectoryCoverage>();

    private void myExit(Exception e) {
        e.printStackTrace();
        System.err.println(e.getClass().getName() + ": " + e.getMessage());
        System.exit(1);
    }

    private Connection connectToDb() {
        Connection dbConnection = null;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            dbConnection = DriverManager.getConnection("jdbc:mysql://" + dbhost
                    + ":" + dbport + "/" + dbname, dbuser, dbpassword);
            System.out.println("Opened database successfully");
        } catch (SQLException | ClassNotFoundException e) {
            myExit(e);
        }
        return dbConnection;
    }

    private void generateDirectoryFuncCovCsv(String sourceDirFilename,
            String outCsvFilename, Integer testrunId, Integer testPosition) {
        System.out.println("Generating directory coverage CSV "
                + outCsvFilename + " for testrunId " + testrunId +" on test position " + testPosition);
        int sourceDirCount = 0;
        // Using a set to ensure we don't do a query for
        // the same directory twice.
        Set<String> directories = new TreeSet<>();
        try (BufferedReader br = new BufferedReader(new FileReader(
                sourceDirFilename))) {
            String line = br.readLine();
            // remove trailing "/"
            if (line.substring(line.length() - 1).equals("/")) {
                line = line.substring(0, line.length() - 1);
            }
            while (line != null) {
                String[] srcDirs = line.split("/");
                String directory = "";
                for (int i = 0; i < srcDirs.length; ++i) {
                    directory += srcDirs[i] + "/";
                    directories.add(directory);
                }
                line = br.readLine();
            }
        } catch (IOException e) {
            myExit(e);
        }
        try {
            long starttime = System.currentTimeMillis();
            {
                Connection dbConnection = connectToDb();
                String selectStmt = "SELECT f_exec_count, fcount, (f_exec_count/fcount * 100.0) as ratio "
                        + "FROM (SELECT SUM(f_exec_count) as f_exec_count, COUNT(DISTINCT func_mangled) as fcount "
                        + "FROM (SELECT  "
                        + "source_files.name as source_file, "
                        + "functions.source_line as source_line, functions.name as function, functions.mangled_name as func_mangled, "
                        + "sum(funccov.visited) as f_exec_count "
                        + "FROM  "
                        + "testruns "
                        + "INNER JOIN tests ON testruns.id = tests.testrun_id "
                        + "INNER JOIN source_files ON source_files.testrun_id = testruns.id "
                        + "INNER JOIN functions ON functions.testrun_id  = testruns.id and functions.source_file_id = source_files.id "
                        + "INNER JOIN funccov ON funccov.testrun_id = testruns.id and funccov.test_id = tests.id and funccov.function_id = functions.id "
                        + "WHERE testruns.id =? AND source_files.name LIKE ?  "
                        + "GROUP BY functions.mangled_name " + ")t1" + ")t2";
                PreparedStatement select = dbConnection
                        .prepareStatement(selectStmt);
                System.out.println(selectStmt);
                CSVWriter writer = new CSVWriter(new FileWriter(outCsvFilename));
                String columns = "path,fexeccount,fcount,ratio";
                writer.writeNext(columns.split(","));
                {
                    for (String directory : directories) {
                        sourceDirCount += 1;
                        String dirPath = directory + "%";
                        select.setInt(1, testrunId);
                        select.setString(2, dirPath);
                        ResultSet rs = select.executeQuery();
                        int fcount = 0;
                        while (rs.next()) {
                            int fexeccount = rs.getInt("f_exec_count");
                            fcount = rs.getInt("fcount");
                            double ratio = rs.getDouble("ratio");
                            String output = "" + directory + "," + fexeccount
                                    + "," + fcount + "," + ratio;
                            writer.writeNext((output).split(","));
                            System.out.print(".");
                            fsTree.add(directory, new DirectoryCoverage(
                                    fexeccount, fcount));
                        }
                        rs.close();
                    }
                }
                writer.close();
                select.close();
                System.out.println("");
            }
            long endtime = System.currentTimeMillis();
            System.out.println("Took: " + ((endtime - starttime) / 1000)
                    + " seconds to generate directory coverage CSV for "
                    + sourceDirCount + " directories.");
        } catch (Exception e) {
            myExit(e);
        }
    }

    // private void loadCsvToFsTree(String inCsvFilename,
    // String outputHTMLFilename, String prologueFilename,
    // String epilogueFilename) {
    // System.out.println("Generating directory coverage HTML file "
    // + outputHTMLFilename + " from " + inCsvFilename);
    //
    // try (FileReader fr = new FileReader(inCsvFilename)) {
    // CSVReader csvReader = new CSVReader(fr);
    // String[] line = csvReader.readNext(); // skip first header row
    // while ((line = csvReader.readNext()) != null) {
    // String directory = line[0];
    // Integer fexeccount = Integer.parseInt(line[1]);
    // Integer fcount = Integer.parseInt(line[2]);
    // fsTree.add(directory, new DirectoryCoverage(fexeccount, fcount));
    // }
    // csvReader.close();
    // } catch (Exception e) {
    // myExit(e);
    // }
    // }

    private void generateHtmlFromFsTree(String outputHTMLFilename) {
        try {
            File outputHTMLFile = new File(outputHTMLFilename);
            Files.copy(new File(prologueFilename).toPath(),
                    outputHTMLFile.toPath(),
                    StandardCopyOption.REPLACE_EXISTING);
            // open output file for appending (by passing true flag)
            BufferedWriter outputFile = new BufferedWriter(new FileWriter(
                    outputHTMLFilename, true));
            outputFile.write("<ul>\n");
            {
                FSTreeIterator<DirectoryCoverage> it = fsTree.iterator();
                int prevDepth = 0;
                String maxString = "                                                                                                                                         ";
                while (it.hasNext()) {
                    it.next();
                    FSTreeNode<DirectoryCoverage> node = it.getNode();
                    Integer depth = it.depth();
                    if (depth < prevDepth) {
                        for (int i = 0; i < (prevDepth - depth); i++) {
                            String spacePrefix1 = maxString.substring(0,
                                    (prevDepth - i) * 2);
                            outputFile.write(spacePrefix1 + "</ul>\n");
                            outputFile.write(spacePrefix1 + "</li>\n");
                        }
                    }
                    prevDepth = depth;
                    String spacePrefix2 = maxString.substring(0, depth * 2);
                    if (node.isLeaf()) {
                        outputFile.write(spacePrefix2 + "<li>"
                                + toHtmlReportEntry(node.name, node.data)
                                + "</li>\n");
                    } else {
                        outputFile.write(spacePrefix2
                                + "<li><span class=\"clickTarget\">"
                                + toHtmlReportEntry(node.name, node.data)
                                + "</span>\n");
                        outputFile.write(spacePrefix2
                                + "<ul class=\"collapsing\">\n");
                    }
                }
            }
            outputFile.write("</ul>\n");
            outputFile.close();

            // Create output stream for appending (by passing true flag)
            FileOutputStream outputStream = new FileOutputStream(
                    outputHTMLFile, true);
            Files.copy(new File(epilogueFilename).toPath(), outputStream);
            outputStream.close();
            System.out.println("Generated HTML file successfully");
        } catch (IOException e) {
            myExit(e);
        } // try... catch for writing HTML output
    }

    private void addHtmlDocToDb(String outputHTMLFilename, Integer testrunId) {
        String updateStmt = "UPDATE testruns SET directory_cov_html=? WHERE id=?";
        System.out.println(updateStmt);
        try {
            Connection dbConnection = connectToDb();
            byte[] encoded = Files.readAllBytes(Paths.get(outputHTMLFilename));
            String htmlDoc = new String(encoded, Charset.forName("UTF-8"));
            PreparedStatement update = dbConnection
                    .prepareStatement(updateStmt);
            update.setString(1, htmlDoc);
            update.setInt(2, testrunId);
            update.executeUpdate();
            update.close();
            System.out
                    .println("Updated directory_cov_html column successfully for testrunId "
                            + testrunId);
        } catch (SQLException | IOException e) {
            myExit(e);
        }
    }

    private String toHtmlReportEntry(String name, DirectoryCoverage dirCov) {
        StringBuffer output = new StringBuffer();
        if (dirCov == null) {
            System.err.println("Null dirCov for " + name);
        } else {
            double funcCoverage = dirCov.functionCoverage();

            String entryClass = "";

            output.append("<table><tbody><tr class=\"coverageData" + entryClass
                    + "\">" + "<td class=\"componentName\">" + name + "/</td>");
            {
                String functionCoverageClass = "";
                {
                    functionCoverageClass = " normal";
                    if (funcCoverage < 33.0) {
                        functionCoverageClass = " critical";
                    } else if (funcCoverage < 66.0) {
                        functionCoverageClass = " warning";
                    }
                }
                output.append("<td class=\"componentFunctionCoverage"
                        + functionCoverageClass + "\">"
                        + dirCov.functionCoverageAsString() + "%</td>");
                {
                    output.append("<td class=\"componentExecutedFunctionCount\">Executed "
                            + dirCov.fexeccount
                            + " out of "
                            + dirCov.fcount
                            + " functions</td>");
                }
                output.append("</tr></tbody></table>");
            }
        }
        return output.toString();
    }

    public void updateDirectorCovHtml() {
        // iterate through the testruns table and update rows with null
        // directory_cov_html

        Connection dbConnection = connectToDb();
        String selectIdStmt = "SELECT id, testposition, directory_cov_html FROM testruns ORDER BY id DESC";
        System.out.println(selectIdStmt);
        try {
            PreparedStatement selectId = dbConnection
                    .prepareStatement(selectIdStmt);
            ResultSet rs = selectId.executeQuery();
            while (rs.next()) {
                Integer testrunId = rs.getInt("id");
                Integer testPosition = rs.getInt("testposition");
                String directory_cov_html = rs.getString("directory_cov_html");
                if (null == directory_cov_html) {
                    String directoryFuncCovCsv = "directoryFuncCov_"+testPosition +"__"+testrunId +".csv";
                    generateDirectoryFuncCovCsv(sourceDirFilename,
                            directoryFuncCovCsv, testrunId, testPosition);
                    String outputHTMLFilename= "function_coverage_"+testPosition +"__"+testrunId +".html";
                    generateHtmlFromFsTree(outputHTMLFilename);
                    addHtmlDocToDb(outputHTMLFilename, testrunId);
                } else {
                    System.err
                            .println("WARNING: directory_cov_html already set for testrunId "
                                    + testrunId + ". Skipping testrunId.");
                }
            }
            rs.close();
            selectId.close();
        } catch (SQLException e) {

            myExit(e);
        }
    }

    public static void main(String args[]) {
        DirectoryCoverageHtmlReport report = new DirectoryCoverageHtmlReport();

        report.dbhost = "localhost";
        report.dbport = "3306";
        report.dbname = "smarttestdb";
        report.dbuser = "root";
        report.dbpassword = "toto";

        if (args.length == 5) {
            report.dbhost = args[0];
            report.dbport = args[1];
            report.dbname = args[2];
            report.dbuser = args[3];
            report.dbpassword = args[4];
        } else {
            System.err.println("Expected 5 arguments got " + args.length
                    + ". Proceeding with default values");
        }

        report.updateDirectorCovHtml();
    }
}
