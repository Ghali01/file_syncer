package com.example.files_syncer

import android.os.Bundle
import android.os.PersistableBundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.ftpserver.FtpServer
import org.apache.ftpserver.FtpServerFactory
import org.apache.ftpserver.ftplet.Authority
import org.apache.ftpserver.ftplet.FtpException
import org.apache.ftpserver.listener.ListenerFactory
import org.apache.ftpserver.usermanager.PropertiesUserManagerFactory
import org.apache.ftpserver.usermanager.SaltedPasswordEncryptor
import org.apache.ftpserver.usermanager.impl.BaseUser
import org.apache.ftpserver.usermanager.impl.WritePermission
import java.io.File
import java.io.IOException

class MainActivity: FlutterActivity() {
    private  val  servers:MutableMap<String,FtpServer> = mutableMapOf()
    private lateinit var channel:MethodChannel


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel= MethodChannel(this.flutterEngine!!.dartExecutor.binaryMessenger,"ftp")
        channel.setMethodCallHandler{
                call,reply->
            when(call.method){
                "start"-> {
                    start(call.arguments as Map<String, Any>)
                }
                "stop"->{
                    stop(call.argument<String>("id")!!)
                }
            }
            reply.success(null)
        }
    }

    private  fun  start(args:Map<String,Any>){

        val ftpServerFactory: FtpServerFactory = FtpServerFactory()
        val ftpServer: FtpServer = ftpServerFactory.createServer()
        val listener: ListenerFactory = ListenerFactory()
        listener.port = args["port"] as Int
        listener.serverAddress=args["host"] as String
        ftpServerFactory.addListener("default", listener.createListener())
        val files = File(getExternalFilesDir("")!!.path.toString() + "/users.properties")
        if (files.isDirectory) {
            files.delete()
        }
        if (!files.exists()) {
            try {
                files.createNewFile()
            } catch (e: IOException) {
                e.printStackTrace()
            }
        }

        val userManagerFactory = PropertiesUserManagerFactory()
        userManagerFactory.file = files
        userManagerFactory.passwordEncryptor = SaltedPasswordEncryptor()
        val um = userManagerFactory.createUserManager()
        val user =
            BaseUser()
        user.name = args["user"]  as String
        user.password = args["password"]  as String
        user.homeDirectory = args["directory"] as String
        val austes = arrayListOf<Authority>(WritePermission())
        user.authorities = austes
        try {
            um.save(user)
        } catch (e1: FtpException) {
            e1.printStackTrace()
        }
        ftpServerFactory.userManager = um

        ftpServer.start()

        servers[args["id"] as String]=ftpServer
    }
    private fun stop(id:String){
        if(servers.containsKey(id)){
            servers[id]!!.stop()
        }
    }
}
