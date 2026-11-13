<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('products', function (Blueprint $t) {
            $t->id('ProductID');
            $t->string('ProductName', 100);
            $t->string('Description', 255)->nullable();
            $t->unsignedBigInteger('CategoryID');
            $t->string('Barcode', 255)->nullable()->index();
            $t->date('Expiredate')->nullable();
            $t->integer('Qty')->default(0);
            $t->decimal('UnitPriceIn', 10, 2)->default(0);
            $t->decimal('UnitPriceOut', 10, 2)->default(0);
            $t->string('ProductImage', 255)->nullable();
            $t->boolean('isDeleted')->default(false);
            $t->foreign('CategoryID')->references('category_id')->on('categories');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
