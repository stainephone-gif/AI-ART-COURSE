package com.sleepwell.app

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.sleepwell.app.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val navHost = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        binding.bottomNav.setupWithNavController(navHost.navController)
    }

    override fun onResume() {
        super.onResume()
        // Check if alarm just dismissed and we need to ask quality
        val prefs = getSharedPreferences("sleepwell", MODE_PRIVATE)
        if (prefs.getBoolean("ask_quality", false)) {
            prefs.edit().remove("ask_quality").apply()
            val navHost = supportFragmentManager
                .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
            navHost.navController.navigate(R.id.statsFragment)
        }
    }
}
