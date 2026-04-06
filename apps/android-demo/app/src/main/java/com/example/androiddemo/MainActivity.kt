package com.example.androiddemo

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private var clickCount = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val titleText: TextView = findViewById(R.id.titleText)
        val messageText: TextView = findViewById(R.id.messageText)
        val clickButton: Button = findViewById(R.id.clickButton)
        val countText: TextView = findViewById(R.id.countText)

        clickButton.setOnClickListener {
            clickCount++
            countText.visibility = View.VISIBLE
            countText.text = getString(R.string.clicked_text, clickCount)

            Toast.makeText(this, "按钮被点击了！", Toast.LENGTH_SHORT).show()
        }
    }
}
