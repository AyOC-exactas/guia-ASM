#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <float.h>

#include "../test-utils.h"
#include "ABI.h"

#define ARR_LENGTH  4
#define ROLL_LENGTH 10

static uint32_t x[ROLL_LENGTH];
static double   f[ROLL_LENGTH];

void shuffle(uint32_t max){
	for (int i = 0; i < ROLL_LENGTH; i++) {
		x[i] = (uint32_t) rand() % max;
        	f[i] = ((float)rand()/(float)(RAND_MAX)) * max;
	}
}

/**
 * Tests ABI
 */

TEST(test_alternate_sum_4) {
	for (int i = 0; i < 100; i++) {
		shuffle(1000);
		sprintf(assert_name, "alternate_sum_4(%u, %u, %u, %u)", x[0], x[1], x[2], x[3]);

		TEST_ASSERT_EQUALS(uint32_t, x[0]-x[1]+x[2]-x[3], TEST_CALL_I(alternate_sum_4, x[0], x[1], x[2], x[3]));
	}
}

TEST(test_alternate_sum_4_using_c) {
	for (int i = 0; i < 100; i++) {
		shuffle(1000);
		sprintf(assert_name, "alternate_sum_4_using_c(%u, %u, %u, %u)", x[0], x[1], x[2], x[3]);

		TEST_ASSERT_EQUALS(uint32_t, x[0]-x[1]+x[2]-x[3], TEST_CALL_I(alternate_sum_4_using_c, x[0], x[1], x[2], x[3]));
	}
}


TEST(test_alternate_sum_8) {
	for (int i = 0; i < 100; i++) {
		shuffle(1000);
		sprintf(assert_name, "alternate_sum_8(%u, %u, %u, %u, %u, %u, %u, %u)", x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]);

		TEST_ASSERT_EQUALS(uint32_t, x[0]-x[1]+x[2]-x[3]+x[4]-x[5]+x[6]-x[7], TEST_CALL_I(alternate_sum_8, x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]));
	}
}

TEST(test_product_2_f) {
	for (int i = 0; i < 100; i++) {
		shuffle(1000);
		sprintf(assert_name, "product_2_f(&result, %u, %.2f)", x[0], f[0]);

		uint32_t result = -1;
		TEST_CALL_V(product_2_f, &result, x[0], f[0]);
		TEST_ASSERT_EQUALS(uint32_t, x[0]*(float)f[0], result);
	}
}


TEST(test_product_9_f) {
	for (int i = 0; i < 100; i++) {
		shuffle(1000);
		sprintf(assert_name, "product_9_f(&result, %u, %.2f, %u, %.2f, %u, %.2f, %u, %.2f, %u, %.2f, %u, %.2f, %u, %.2f, %u, %.2f, %u, %.2f)",
		                     x[0], f[0], x[1], f[1], x[2], f[2], x[3], f[3], x[4], f[4], x[5], f[5], x[6], f[6], x[7], f[7], x[8], f[8]);

        	double expected = f[0] * f[1] * f[2] * f[3] * f[4] * f[5] * f[6] * f[7] * f[8]
        	                * x[0] * x[1] * x[2] * x[3] * x[4] * x[5] * x[6] * x[7] * x[8];
		double result = 1.0/0.0;
        product_9_f(&result, x[0], f[0], x[1], f[1], x[2], f[2], x[3], f[3], x[4], f[4], x[5], f[5], x[6], f[6], x[7], f[7], x[8], f[8]);

		TEST_ASSERT_EQUALS(double, expected, result);
	}
}


int main() {
	srand(0);

    char test_suite_name[] = "ABI";

	printf("==============\n");
	printf("= %s \n", test_suite_name);
	printf("==============\n");
	test_alternate_sum_4();
	test_alternate_sum_4_using_c();
	test_alternate_sum_8();
	test_product_2_f();
	test_product_9_f();
	printf("\n");

	tests_end(test_suite_name);
	return 0;
}
